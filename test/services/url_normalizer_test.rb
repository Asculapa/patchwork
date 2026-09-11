require "test_helper"

class UrlNormalizerTest < ActiveSupport::TestCase
  test "adds https to bare hosts, lowercases the host and drops fragments and default ports" do
    assert_equal "https://example.com/", UrlNormalizer.call("Example.COM")
    assert_equal "https://example.com/blog", UrlNormalizer.call("  https://EXAMPLE.com:443/blog#top ")
    assert_equal "https://example.com/feed", UrlNormalizer.call("//example.com/feed")
  end

  test "strips tracking parameters but keeps the rest of the query" do
    assert_equal "https://example.com/feed?page=2", UrlNormalizer.call("https://example.com/feed?utm_source=x&page=2&fbclid=1")
    assert_equal "https://example.com/feed", UrlNormalizer.call("https://example.com/feed?utm_medium=rss")
  end

  test "rejects anything that isn't an absolute http(s) URL" do
    assert_nil UrlNormalizer.call("ftp://example.com/feed")
    assert_nil UrlNormalizer.call("")
    assert_nil UrlNormalizer.call(nil)
  end

  test "resolves relative links against a base" do
    assert_equal "https://example.com/about", UrlNormalizer.resolve("/about", base: "https://example.com/posts/1")
    assert_equal "https://cdn.example.com/x.png", UrlNormalizer.resolve("//cdn.example.com/x.png", base: "https://example.com/")
    assert_nil UrlNormalizer.resolve("mailto:hi@example.com", base: "https://example.com/")
    assert_nil UrlNormalizer.resolve("javascript:alert(1)", base: "https://example.com/")
  end
end
