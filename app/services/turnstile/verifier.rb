module Turnstile
  # Server-side check for Cloudflare Turnstile (registration's CAPTCHA). Skipped
  # entirely when no secret key is configured, so it's a no-op in development
  # and test.
  class Verifier
    VERIFY_URL = URI("https://challenges.cloudflare.com/turnstile/v0/siteverify")

    class << self
      def enabled? = ENV["TURNSTILE_SECRET_KEY"].present?

      def verify(token, remote_ip:)
        return true unless enabled?
        return false if token.blank?

        response = Net::HTTP.post_form(VERIFY_URL, secret: ENV["TURNSTILE_SECRET_KEY"], response: token, remoteip: remote_ip)
        JSON.parse(response.body)["success"] == true
      rescue StandardError
        false
      end
    end
  end
end
