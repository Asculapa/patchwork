require "test_helper"

class SiteIconTest < ActiveSupport::TestCase
  test "picks the page's favicon link, resolved to an absolute URL" do
    stub_get "https://example.com/", fixture: "pages/with_icons.html", content_type: "text/html"
    stub_request(:get, "https://example.com/assets/favicon.png").to_return(status: 200)

    assert_equal "https://example.com/assets/favicon.png", SiteIcon.fetch("https://example.com/")
  end

  test "prefers the social image when asked (YouTube channel avatars)" do
    stub_get "https://example.com/", fixture: "pages/with_icons.html", content_type: "text/html"
    stub_request(:get, "https://example.com/social.png").to_return(status: 200)

    assert_equal "https://example.com/social.png", SiteIcon.fetch("https://example.com/", prefer_social_image: true)
  end

  test "skips candidates that don't actually load and falls back to /favicon.ico" do
    stub_get "https://example.com/", fixture: "pages/with_icons.html", content_type: "text/html"
    stub_request(:get, "https://example.com/assets/favicon.png").to_return(status: 404)
    stub_request(:get, "https://example.com/assets/apple-touch.png").to_return(status: 404)
    stub_request(:get, "https://example.com/social.png").to_return(status: 404)
    stub_request(:get, "https://example.com/favicon.ico").to_return(status: 200)

    assert_equal "https://example.com/favicon.ico", SiteIcon.fetch("https://example.com/")
  end

  test "returns nil when nothing on the page loads" do
    stub_get "https://example.com/", fixture: "pages/blog.html", content_type: "text/html"
    stub_request(:get, "https://example.com/favicon.ico").to_return(status: 404)

    assert_nil SiteIcon.fetch("https://example.com/")
  end

  test "returns nil instead of raising when the page can't be fetched" do
    stub_request(:get, "https://example.com/").to_raise(SocketError)

    assert_nil SiteIcon.fetch("https://example.com/")
  end
end
