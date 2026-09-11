class Group < ApplicationRecord
  belongs_to :user
  has_many :subscriptions, dependent: :nullify

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, length: { maximum: 50 },
    uniqueness: { scope: :user_id, case_sensitive: false }

  scope :alphabetical, -> { order(Arel.sql("LOWER(groups.name)")) }
end
