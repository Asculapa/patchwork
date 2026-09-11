require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "show" do
    get settings_path
    assert_select "select[name='user[time_zone]']"
  end

  test "update the time zone" do
    patch settings_path, params: { user: { time_zone: "Tokyo" } }
    assert_redirected_to settings_path
    assert_equal "Tokyo", users(:one).reload.time_zone
  end
end
