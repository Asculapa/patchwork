require "test_helper"

class SourceResolverTest < ActiveSupport::TestCase
  YOUTUBE_FEED = "https://www.youtube.com/feeds/videos.xml?channel_id=UC_x5XG1OV2P6uZZ5FSM9Ttw"

  test "a feed URL resolves to itself with a preview" do
    stub_get "https://example.com/feed.xml", fixture: "feeds/rss.xml"

    candidate, = SourceResolver.call("https://example.com/feed.xml")

    assert_equal "https://example.com/feed.xml", candidate.url
    assert_equal "feed", candidate.kind
    assert_equal "Example Blog", candidate.title
    assert_equal 2, candidate.entries.size
  end

  test "web pages are resolved through autodiscovery, preferring non-comment feeds" do
    stub_get "https://example.com/", fixture: "pages/blog.html", content_type: "text/html"
    stub_get "https://example.com/feed.xml", fixture: "feeds/rss.xml"
    stub_get "https://example.com/comments/feed", fixture: "feeds/atom.xml"

    candidates = SourceResolver.call("example.com")

    assert_equal [ "https://example.com/feed.xml", "https://example.com/comments/feed" ], candidates.map(&:url)
  end

  test "falls back to common feed paths" do
    stub_request(:get, /example\.com/).to_return(status: 404)
    stub_get "https://example.com/", fixture: "pages/no_feed.html", content_type: "text/html"
    stub_get "https://example.com/rss.xml", fixture: "feeds/rss.xml"

    assert_equal [ "https://example.com/rss.xml" ], SourceResolver.call("https://example.com/").map(&:url)
  end

  test "returns no candidates when a site has no feed" do
    stub_request(:get, /example\.com/).to_return(status: 404)
    stub_get "https://example.com/", fixture: "pages/no_feed.html", content_type: "text/html"

    assert_empty SourceResolver.call("https://example.com/")
  end

  test "YouTube @handles are resolved from the channel page" do
    stub_get "https://www.youtube.com/@GoogleDevelopers", fixture: "pages/youtube_channel.html", content_type: "text/html"
    stub_get YOUTUBE_FEED, fixture: "feeds/youtube.xml"

    candidate, = SourceResolver.call("@GoogleDevelopers")

    assert_equal "youtube", candidate.kind
    assert_equal YOUTUBE_FEED, candidate.url
    assert_equal "Google for Developers", candidate.title
  end

  test "YouTube channel URLs map straight to the feed" do
    stub_get YOUTUBE_FEED, fixture: "feeds/youtube.xml"

    assert_equal [ YOUTUBE_FEED ], SourceResolver.call("https://youtube.com/channel/UC_x5XG1OV2P6uZZ5FSM9Ttw").map(&:url)
    assert_not_requested :get, "https://www.youtube.com/channel/UC_x5XG1OV2P6uZZ5FSM9Ttw"
  end

  test "Medium, Substack and Reddit URLs map to their feeds" do
    stub_get "https://medium.com/feed/@ada", fixture: "feeds/rss.xml"
    stub_get "https://news.substack.com/feed", fixture: "feeds/rss.xml"
    stub_get "https://www.reddit.com/r/ruby/.rss", fixture: "feeds/atom.xml"

    assert_equal [ "https://medium.com/feed/@ada" ], SourceResolver.call("https://medium.com/@ada/some-post-123").map(&:url)
    assert_equal [ "https://news.substack.com/feed" ], SourceResolver.call("news.substack.com/p/hello").map(&:url)
    assert_equal [ "https://www.reddit.com/r/ruby/.rss" ], SourceResolver.call("https://old.reddit.com/r/ruby/").map(&:url)
  end

  test "private addresses are refused" do
    with_resolver(->(_host) { [ IPAddr.new("10.0.0.5") ] }) do
      error = assert_raises(SourceResolver::Error) { SourceResolver.call("http://intranet.example/") }
      assert_match "private or local networks", error.message
    end
  end

  test "input that isn't a web address is refused" do
    assert_raises(SourceResolver::Error) { SourceResolver.call("ftp://example.com") }
  end
end
