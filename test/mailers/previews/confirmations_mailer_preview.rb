# Preview all emails at http://localhost:3000/rails/mailers/confirmations_mailer
class ConfirmationsMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/confirmations_mailer/confirm
  def confirm
    ConfirmationsMailer.confirm(User.take)
  end
end
