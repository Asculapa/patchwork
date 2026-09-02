# Registers/unregisters this browser's PushManager subscription so
# SendDigestNotificationsJob can reach it. The subscription's endpoint URL
# (unique per browser/device) doubles as the :id, since the client only ever
# knows its own endpoint, not a database id.
class PushSubscriptionsController < ApplicationController
  def create
    subscription = Current.user.push_subscriptions.find_or_initialize_by(endpoint: params[:endpoint])
    subscription.assign_attributes(p256dh_key: params[:p256dh_key], auth_key: params[:auth_key])

    if subscription.save
      head :created
    else
      render json: { errors: subscription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    Current.user.push_subscriptions.find_by(endpoint: params[:id])&.destroy
    head :no_content
  end

  # Sends an immediate push to the calling device's own subscription, so a
  # user can confirm push actually arrives (e.g. on an iOS/Android PWA added
  # to the home screen) without waiting for the next digest slot.
  def test
    subscription = Current.user.push_subscriptions.find_by(endpoint: params[:endpoint])
    return render json: { errors: [ "Not subscribed on this device" ] }, status: :not_found unless subscription

    if WebPushDelivery.send(subscription, title: "Test notification from Patchwork", path: settings_path)
      head :no_content
    else
      render json: { errors: [ "This device's subscription is no longer valid. Re-enable notifications and try again." ] }, status: :unprocessable_entity
    end
  end
end
