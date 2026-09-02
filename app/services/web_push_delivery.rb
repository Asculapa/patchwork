# Sends a single Web Push message to one subscription. Shared by
# SendDigestNotificationsJob and the settings "send test notification"
# action so both go through the same VAPID/payload plumbing and the same
# stale-subscription cleanup.
class WebPushDelivery
  def self.send(subscription, title:, path: nil)
    Webpush.payload_send(
      message: { title: title, options: { data: { path: path } } }.to_json,
      endpoint: subscription.endpoint,
      p256dh: subscription.p256dh_key,
      auth: subscription.auth_key,
      vapid: {
        subject: Rails.application.credentials.dig(:vapid, :subject),
        public_key: Rails.application.credentials.dig(:vapid, :public_key),
        private_key: Rails.application.credentials.dig(:vapid, :private_key)
      }
    )
    true
  rescue Webpush::InvalidSubscription, Webpush::ExpiredSubscription
    subscription.destroy
    false
  end
end
