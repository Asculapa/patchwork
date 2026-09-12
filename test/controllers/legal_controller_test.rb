require "test_helper"

class LegalControllerTest < ActionDispatch::IntegrationTest
  test "privacy is accessible without signing in" do
    get privacy_path
    assert_response :success
  end

  test "terms is accessible without signing in" do
    get terms_path
    assert_response :success
  end
end
