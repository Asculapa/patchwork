require "test_helper"

class FeedDocumentTest < ActiveSupport::TestCase
  test "parses RSS into sanitised entries with absolute URLs" do
    document = FeedDocument.parse(file_fixture("feeds/rss.xml").read, url: "https://example.com/feed.xml")

    assert_equal "Example Blog", document.title
    assert_equal "Posts about things", document.description
    assert_equal "https://example.com/", document.site_url
    assert_equal "https://example.com/icon.png", document.icon_url
    assert_equal 120.minutes, document.min_interval

    second, first = document.entries
    assert_equal "post-2", second.guid
    assert_equal "Second post & more", second.title
    assert_equal "https://example.com/posts/second", second.url
    assert_equal "Ada Lovelace", second.author
    assert_equal Time.utc(2026, 9, 9, 10), second.published_at
    assert_includes second.content_html, %(href="https://example.com/about")
    assert_no_match(/script|onclick|iframe|pixel\.wp\.com/, second.content_html)
    assert_equal "https://example.com/images/cover.jpg", second.image_url

    assert_equal "https://example.com/posts/first", first.guid, "falls back to the link when there is no guid"
    assert_nil first.image_url, "audio enclosures are not thumbnails"
  end

  test "parses Atom and clamps dates in the future" do
    freeze_time do
      document = FeedDocument.parse(file_fixture("feeds/atom.xml").read, url: "https://atom.example.com/feed.atom")
      entry, future = document.entries

      assert_equal "https://atom.example.com/", document.site_url
      assert_equal "https://atom.example.com/favicon.ico", document.icon_url
      assert_equal "urn:uuid:entry-1", entry.guid
      assert_equal "Grace Hopper", entry.author
      assert_equal "<p>Atom body</p>", entry.content_html
      assert_equal Time.current, future.published_at
      assert_equal "Summary only", future.summary
    end
  end

  test "parses YouTube feeds into video entries" do
    document = FeedDocument.parse(file_fixture("feeds/youtube.xml").read, url: "https://www.youtube.com/feeds/videos.xml?channel_id=UC_x5XG1OV2P6uZZ5FSM9Ttw")
    video = document.entries.first

    assert_equal "Google for Developers", document.title
    assert_equal "yt:video:abcDEF12345", video.guid
    assert_equal "yt:video:abcDEF12345", video.fingerprint
    assert_equal "abcDEF12345", video.media["video_id"]
    assert_equal "https://i2.ytimg.com/vi/abcDEF12345/hqdefault.jpg", video.image_url
    assert_includes video.content_html, %(<a href="https://goo.gle/android")
    assert_includes video.content_html, "&lt;b&gt;not bold&lt;/b&gt;", "descriptions are plain text"
  end

  test "parses JSON Feed" do
    document = FeedDocument.parse(file_fixture("feeds/json_feed.json").read, url: "https://json.example.com/feed.json")
    item = document.entries.first

    assert_equal "JSON Example", document.title
    assert_equal "json-1", item.guid
    assert_equal "<p>Hi from JSON</p>", item.content_html
    assert_equal "https://json.example.com/1.png", item.image_url
  end

  test "rejects web pages and garbage" do
    assert_raises(FeedDocument::Invalid) { FeedDocument.parse(file_fixture("pages/blog.html").read, url: "https://example.com/") }
    assert_raises(FeedDocument::Invalid) { FeedDocument.parse("not a feed", url: "https://example.com/") }
  end
end
