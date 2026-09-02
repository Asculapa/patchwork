require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "shows the landing page to signed-out visitors" do
    get root_path

    assert_response :success
    assert_select "h1", text: /All your feeds/
  end

  test "redirects signed-in users to their entries" do
    sign_in_as users(:one)

    get root_path

    assert_redirected_to entries_path
  end
end
