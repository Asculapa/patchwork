# Something that produces entries. Shared sources are fetched once no matter
# how many users follow them.
class Source < ApplicationRecord
  DEFAULT_INTERVAL = 1.hour
  MIN_INTERVAL = 15.minutes
  MAX_INTERVAL = 24.hours
  # How long a source stays out of the schedule while its fetch job is queued.
  FETCH_LEASE = 15.minutes
  MAX_ERRORS = 10

  enum :kind, { feed: "feed", youtube: "youtube" }
  enum :visibility, { shared: "shared", private: "private" }, prefix: true
  enum :status, { active: "active", paused: "paused", error: "error" }

  belongs_to :owner, class_name: "User", optional: true
  has_many :subscriptions, dependent: :destroy
  has_many :entries, dependent: :delete_all
  has_many :fetch_logs, dependent: :delete_all

  normalizes :url, with: ->(url) { UrlNormalizer.call(url) || url.strip }

  validates :url, presence: true
  validates :url, uniqueness: true, if: :visibility_shared?

  scope :subscribed, -> { where(id: Subscription.select(:source_id)) }
  scope :due, -> { active.subscribed.where("next_fetch_at IS NULL OR next_fetch_at <= ?", Time.current) }

  before_create { self.next_fetch_at ||= Time.current }

  def self.kind_for_url(url)
    uri = URI.parse(url.to_s)
    uri.host.to_s.end_with?("youtube.com") && uri.path == "/feeds/videos.xml" ? "youtube" : "feed"
  rescue URI::InvalidURIError
    "feed"
  end

  def display_title
    title.presence || URI.parse(site_url.presence || url).host.to_s.delete_prefix("www.")
  rescue URI::InvalidURIError
    url
  end

  def fetcher_class
    Fetchers::Feed
  end

  def failing?
    error_count.positive?
  end

  def record_success!(result, new_entries_count)
    interval = new_entries_count.positive? ? fetch_interval / 2 : fetch_interval * 3 / 2
    interval = interval.clamp(MIN_INTERVAL.to_i, MAX_INTERVAL.to_i)
    interval = [ [ interval, result.min_interval.to_i ].max, MAX_INTERVAL.to_i ].min

    now = Time.current
    attributes = {
      status: :active, error_count: 0, last_error: nil,
      last_fetched_at: now, next_fetch_at: now + interval, fetch_interval: interval
    }

    if result.not_modified
      attributes[:etag] = result.etag if result.etag
    else
      attributes.merge!(
        etag: result.etag, last_modified: result.last_modified,
        title: result.title.presence || title,
        site_url: result.site_url.presence || site_url,
        icon_url: result.icon_url.presence || icon_url,
        description: result.description.presence || description
      )
    end

    attributes[:url] = result.permanent_url if moved_permanently_to?(result.permanent_url)
    update!(attributes)
  end

  def record_failure!(message, status: nil)
    count = error_count + 1
    backoff = [ fetch_interval * 2**[ count, 10 ].min, MAX_INTERVAL.to_i ].min
    status ||= :error if count >= MAX_ERRORS

    update!(
      error_count: count, last_error: message.to_s.truncate(500),
      last_fetched_at: Time.current, next_fetch_at: backoff.seconds.from_now,
      status: status || self.status
    )
  end

  private
    def moved_permanently_to?(new_url)
      new_url = UrlNormalizer.call(new_url)
      new_url.present? && new_url != url && !Source.visibility_shared.exists?(url: new_url)
    end
end
