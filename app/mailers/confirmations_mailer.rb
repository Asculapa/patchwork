class ConfirmationsMailer < ApplicationMailer
  def confirm(user)
    @user = user
    @token = user.generate_token_for(:email_confirmation)
    mail subject: "Confirm your email", to: user.email_address
  end
end
