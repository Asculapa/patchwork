require "test_helper"

class SitemapControllerTest < ActionDispatch::IntegrationTest
  test "is accessible without signing in and lists the public pages" do
    get sitemap_path

    assert_response :success
    assert_equal "application/xml", response.media_type
    assert_includes response.body, "<loc>#{root_url}</loc>"
    assert_includes response.body, "<loc>#{privacy_url}</loc>"
    assert_includes response.body, "<loc>#{terms_url}</loc>"
  end

  test "does not list pages that require signing in" do
    get sitemap_path

    assert_not_includes response.body, entries_path
    assert_not_includes response.body, new_session_path
  end
end
