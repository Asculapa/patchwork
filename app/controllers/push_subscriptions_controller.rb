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
end
