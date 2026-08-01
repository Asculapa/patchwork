# Be sure to restart your server when you modify this file.

# Feed content is sanitised at ingest; the CSP is the second line of defence
# (§7.1). Images may come from any https host; the only embeddable frames are
# privacy-enhanced YouTube players.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri    :self
    policy.connect_src :self
    policy.font_src    :self, :data
    policy.form_action :self
    policy.frame_ancestors :none
    policy.frame_src   "https://www.youtube-nocookie.com"
    policy.img_src     :self, :https, :data
    policy.media_src   :self, :https
    policy.object_src  :none
    policy.script_src  :self
    policy.style_src   :self
  end

  # Nonces for the importmap and Turbo's progress bar styles. They stay stable
  # for a session so Turbo doesn't see the tracked importmap tag change on every
  # visit. Stored in the session rather than derived from session.id, which is
  # still empty on a visitor's first request and would block all JavaScript.
  config.content_security_policy_nonce_generator = ->(request) { request.session[:csp_nonce] ||= SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
