# A user's state (read, starred) for one entry. Created for every subscriber
# when an entry is ingested, so all reading views are single-table lookups.
class UserEntry < ApplicationRecord
  TODAY_WINDOW = 24.hours

  belongs_to :user
  belongs_to :entry
  belongs_to :subscription

  scope :unread, -> { where(read_at: nil) }
  scope :starred, -> { where.not(starred_at: nil) }
  scope :unmuted, -> { joins(:subscription).where(subscriptions: { muted: false }) }
  scope :today, -> { where(published_at: TODAY_WINDOW.ago..) }
  scope :newest_first, -> { order(published_at: :desc, id: :desc) }

  def read?
    read_at.present?
  end

  def starred?
    starred_at.present?
  end

  def mark_read!
    update!(read_at: Time.current) unless read?
  end

  def mark_unread!
    update!(read_at: nil)
  end

  def star!
    update!(starred_at: Time.current) unless starred?
  end

  def unstar!
    update!(starred_at: nil)
  end
end
