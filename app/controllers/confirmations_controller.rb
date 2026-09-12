class ConfirmationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_confirmation_path, alert: "Try again later." }
  layout "auth"

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      user.deliver_email_confirmation unless user.confirmed?
    end

    redirect_to new_session_path, notice: "Confirmation instructions sent (if an unconfirmed account with that email address exists)."
  end

  def show
    if user = User.find_by_token_for(:email_confirmation, params[:token])
      user.confirm!
      start_new_session_for user
      redirect_to root_path, notice: "Email confirmed. Welcome to Patchwork!"
    else
      redirect_to new_confirmation_path, alert: "Confirmation link is invalid or has expired."
    end
  end
end
