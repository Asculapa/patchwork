require "test_helper"

class OpmlControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "export downloads an OPML file" do
    get opml_path

    assert_response :success
    assert_equal "text/x-opml", response.media_type
    assert_includes response.body, %(xmlUrl="https://example.com/feed.xml")
  end

  test "import shows a summary" do
    post opml_path, params: { file: fixture_file_upload("subscriptions.opml", "text/x-opml") }

    assert_response :success
    assert_select ".page-title", "Import finished"
    assert users(:one).subscriptions.joins(:source).exists?(sources: { url: "https://loose.example.com/rss" })
  end

  test "import without a file or with a bad file redirects with an error" do
    post opml_path
    assert_redirected_to new_opml_path

    post opml_path, params: { file: fixture_file_upload("pages/no_feed.html", "text/html") }
    assert_redirected_to new_opml_path
    assert flash[:alert].present?
  end
end
