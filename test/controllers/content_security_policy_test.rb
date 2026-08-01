require "test_helper"

class ContentSecurityPolicyTest < ActionDispatch::IntegrationTest
  test "a first-time visitor gets a real nonce on the importmap scripts" do
    get new_session_path

    nonces = css_select("script").map { |script| script["nonce"] }
    assert nonces.any?
    assert nonces.all?(&:present?), "empty nonces make the browser block all JavaScript"
    assert_includes response.headers["Content-Security-Policy"], "'nonce-#{nonces.first}'"
  end

  test "the nonce stays the same across a session so Turbo doesn't reload the page" do
    get new_session_path
    first = css_select("script[type=importmap]").first["nonce"]

    get new_registration_path
    assert_equal first, css_select("script[type=importmap]").first["nonce"]
  end
end
