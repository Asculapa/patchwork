# A user following a source, with their own title, group and mute setting.
class Subscription < ApplicationRecord
  BACKFILL_LIMIT = 100

  belongs_to :user
  belongs_to :source
  belongs_to :group, optional: true
  has_many :user_entries, dependent: :delete_all

  normalizes :custom_title, with: ->(title) { title.squish.presence }

  validates :source_id, uniqueness: { scope: :user_id, message: "is already one of your sources" }
  validate :group_belongs_to_user

  scope :unmuted, -> { where(muted: false) }
  scope :alphabetical, -> {
    joins(:source).order(Arel.sql("LOWER(COALESCE(subscriptions.custom_title, sources.title, sources.url))"))
  }

  after_create_commit :backfill_entries

  def title
    custom_title || source.display_title
  end

  private
    def group_belongs_to_user
      errors.add(:group, "must be one of your groups") if group && group.user_id != user_id
    end

    # Entries fetched before this user subscribed are shared, so give the new
    # subscriber their own state rows for the most recent ones.
    def backfill_entries
      entries = source.entries.order(published_at: :desc).limit(BACKFILL_LIMIT).pluck(:id, :published_at)
      return if entries.empty?

      rows = entries.map do |entry_id, published_at|
        { user_id: user_id, entry_id: entry_id, subscription_id: id, published_at: published_at }
      end
      UserEntry.insert_all(rows, unique_by: %i[user_id entry_id])
    end
end
