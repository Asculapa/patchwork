require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get new_registration_path
    assert_response :success
  end

  test "create signs the new user in and maps the browser time zone" do
    assert_difference -> { User.count } do
      post registration_path, params: { user: {
        email_address: "New@Example.com", password: "password123", password_confirmation: "password123", time_zone: "Europe/Kyiv"
      } }
    end

    assert_redirected_to new_subscription_path
    user = User.find_by!(email_address: "new@example.com")
    assert_equal "Europe/Kyiv", user.time_zone
    assert cookies[:session_id].present?
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
end
