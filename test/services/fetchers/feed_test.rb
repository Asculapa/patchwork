require "test_helper"

module Fetchers
  class FeedTest < ActiveSupport::TestCase
    test "falls back to the channel avatar when a YouTube feed has no icon of its own" do
      source = sources(:youtube)
      stub_get source.url, fixture: "feeds/youtube.xml"
      stub_get "https://www.youtube.com/channel/UC_x5XG1OV2P6uZZ5FSM9Ttw", fixture: "pages/with_icons.html", content_type: "text/html"
      stub_request(:get, "https://www.youtube.com/social.png").to_return(status: 200)

      result = Feed.new(source).fetch

      assert_equal "https://www.youtube.com/social.png", result.icon_url
    end

    test "does not re-scrape once the source already has an icon" do
      source = sources(:youtube)
      source.update!(icon_url: "https://example.com/existing.png")
      stub_get source.url, fixture: "feeds/youtube.xml"

      result = Feed.new(source).fetch

      assert_nil result.icon_url, "no new icon was found, but the existing one is preserved by Source#record_success!"
    end
  end
end
