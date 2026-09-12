require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get new_registration_path
    assert_response :success
  end

  test "create sends a confirmation email and maps the browser time zone, without signing in" do
    assert_difference -> { User.count } do
      post registration_path, params: { user: {
        email_address: "New@Example.com", password: "password123", password_confirmation: "password123", time_zone: "Europe/Kyiv"
      } }
    end

    assert_redirected_to new_session_path
    user = User.find_by!(email_address: "new@example.com")
    assert_equal "Europe/Kyiv", user.time_zone
    assert_not user.confirmed?
    assert_enqueued_email_with ConfirmationsMailer, :confirm, args: [ user ]
    assert_nil cookies[:session_id]
  end

  test "create with invalid data shows errors" do
    assert_no_difference -> { User.count } do
      post registration_path, params: { user: { email_address: "bad", password: "short", password_confirmation: "short" } }
    end
    assert_response :unprocessable_entity
  end

  test "an unknown time zone falls back to UTC" do
    post registration_path, params: { user: {
      email_address: "tz@example.com", password: "password123", password_confirmation: "password123", time_zone: "Mars/Olympus"
    } }
    assert_equal "UTC", User.find_by!(email_address: "tz@example.com").time_zone
  end

  test "create fails Turnstile verification when configured and no token is submitted" do
    ENV["TURNSTILE_SECRET_KEY"] = "test-secret"

    assert_no_difference -> { User.count } do
      post registration_path, params: { user: {
        email_address: "captcha@example.com", password: "password123", password_confirmation: "password123", time_zone: "UTC"
      } }
    end
    assert_response :unprocessable_entity
  ensure
    ENV.delete("TURNSTILE_SECRET_KEY")
  end
end
