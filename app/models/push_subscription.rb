# One browser/device registration for Web Push, created from the
# PushManager subscription the client obtains via the service worker.
class PushSubscription < ApplicationRecord
  belongs_to :user

  validates :endpoint, :p256dh_key, :auth_key, presence: true
  validates :endpoint, uniqueness: true
end
