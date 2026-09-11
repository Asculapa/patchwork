# Which entries a reading view shows (Today, All unread, Starred, All, a group
# or a single source) and how to page through them.
class EntryFilter
  VIEWS = %w[today unread starred all].freeze
  TITLES = { "today" => "Today", "unread" => "All unread", "starred" => "Starred", "all" => "All entries" }.freeze
  PER_PAGE = 50
  TODAY_LIMIT = 500

  attr_reader :view, :group, :subscription

  def initialize(user, params)
    @user = user
    @group = user.groups.find(params[:group_id]) if params[:group_id].present?
    @subscription = user.subscriptions.find(params[:subscription_id]) if params[:subscription_id].present?
    @view = VIEWS.include?(params[:view]) ? params[:view] : default_view
  end

  def today?
    view == "today"
  end

  # Showing one group or source rather than a global view.
  def narrowed?
    group.present? || subscription.present?
  end

  def title
    subscription&.title || group&.name || TITLES.fetch(view)
  end

  def to_params(**extra)
    { group_id: group&.id, subscription_id: subscription&.id }
      .merge(view == default_view ? {} : { view: view })
      .merge(extra).compact
  end

  def scope
    entries = @user.user_entries
    entries = entries.where(subscription: subscription) if subscription
    entries = entries.joins(:subscription).where(subscriptions: { group_id: group.id }) if group
    entries = entries.unmuted unless subscription || view == "starred"

    case view
    when "today" then entries.unread.today
    when "unread" then entries.unread
    when "starred" then entries.starred
    else entries
    end
  end

  # Keyset pagination; returns [user_entries, cursor_for_next_page_or_nil].
  def page(before: nil)
    entries = scope.newest_first.includes(entry: :source, subscription: :source)
    if (time, id = parse_cursor(before))
      entries = entries.where(
        "user_entries.published_at < :time OR (user_entries.published_at = :time AND user_entries.id < :id)",
        time: time, id: id
      )
    end

    records = entries.limit(PER_PAGE + 1).to_a
    next_cursor = cursor_for(records[PER_PAGE - 1]) if records.size > PER_PAGE
    [ records.first(PER_PAGE), next_cursor ]
  end

  # Today's entries grouped by group (named groups first), then by source.
  def today_sections
    records = scope.newest_first.includes(entry: :source, subscription: %i[source group]).limit(TODAY_LIMIT).to_a
    records
      .group_by { |user_entry| user_entry.subscription.group }
      .sort_by { |group, _| group ? [ 0, group.name.downcase ] : [ 1, "" ] }
      .map { |group, user_entries| [ group, user_entries.group_by(&:subscription) ] }
  end

  private
    def default_view
      narrowed? ? "unread" : "today"
    end

    def cursor_for(user_entry)
      "#{user_entry.published_at.utc.iso8601(6)}_#{user_entry.id}"
    end

    def parse_cursor(cursor)
      time, _, id = cursor.to_s.rpartition("_")
      [ Time.iso8601(time), Integer(id) ] if time.present?
    rescue ArgumentError
      nil
    end
end
