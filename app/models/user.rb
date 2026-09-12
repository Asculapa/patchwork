class User < ApplicationRecord
  has_secure_password
  generates_token_for :email_confirmation, expires_in: 1.day do
    email_address
  end

  has_many :sessions, dependent: :destroy
  has_many :groups, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :user_entries, dependent: :delete_all
  has_many :sources, through: :subscriptions
  has_many :push_subscriptions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  # Browsers report IANA names ("Europe/Kyiv"), the settings page Rails names
  # ("Tokyo"); both work with Time.use_zone. Anything else falls back to UTC.
  normalizes :time_zone, with: ->(zone) { ActiveSupport::TimeZone[zone].present? ? zone : "UTC" }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :time_zone, presence: true

  def confirmed?
    confirmed_at.present?
  end

  def confirm!
    update!(confirmed_at: Time.current)
  end

  def deliver_email_confirmation
    ConfirmationsMailer.confirm(self).deliver_later
  end
end
