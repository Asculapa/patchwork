# Runs every 15 minutes (config/recurring.yml). For each user with at least
# one push subscription, checks whether it's currently 9am or 9pm in THEIR
# time zone and, if so and they haven't already been notified for that slot
# today, pushes an unread count reminder to every one of their devices.
class SendDigestNotificationsJob < ApplicationJob
  queue_as :default

  SLOTS = { 9 => :morning, 21 => :evening }.freeze

  def perform
    User.joins(:push_subscriptions).distinct.find_each do |user|
      local_time = Time.current.in_time_zone(user.time_zone)
      slot = SLOTS[local_time.hour]
      next unless slot

      column = :"last_#{slot}_notification_on"
      next if user[column] == local_time.to_date

      count = user.user_entries.unmuted.unread.count
      notify(user, count) if count.positive?
      user.update_column(column, local_time.to_date)
    end
  end

  private
    def notify(user, count)
      message = "There #{count == 1 ? "is" : "are"} #{helpers.pluralize(count, "new article")} to read!"

      user.push_subscriptions.find_each do |subscription|
        send_push(subscription, title: message)
      end
    end

    def send_push(subscription, title:)
      Webpush.payload_send(
        message: { title: title, options: { data: { path: Rails.application.routes.url_helpers.entries_path } } }.to_json,
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh_key,
        auth: subscription.auth_key,
        vapid: {
          subject: Rails.application.credentials.dig(:vapid, :subject),
          public_key: Rails.application.credentials.dig(:vapid, :public_key),
          private_key: Rails.application.credentials.dig(:vapid, :private_key)
        }
      )
    rescue Webpush::InvalidSubscription, Webpush::ExpiredSubscription
      subscription.destroy
    end

    def helpers
      ActionController::Base.helpers
    end
end
