class SourceResolver
  # Channels, @handles, videos and playlists all map to YouTube's Atom feeds.
  module YouTube
    HOSTS = %w[youtube.com www.youtube.com m.youtube.com music.youtube.com youtu.be].freeze
    FEED_URL = "https://www.youtube.com/feeds/videos.xml"
    CHANNEL_ID = /UC[\w-]{22}/
    # Skips the EU cookie-consent interstitial so the real page is returned.
    PAGE_HEADERS = { "Cookie" => "SOCS=CAI; CONSENT=YES+1", "Accept-Language" => "en-US,en;q=0.8" }.freeze

    module_function

    def match?(uri)
      HOSTS.include?(uri.host)
    end

    def feed_urls(uri)
      playlist_id = (uri.query_values || {})["list"].to_s

      case uri.path
      when "/feeds/videos.xml"
        [ uri.to_s ]
      when "/playlist"
        playlist_id.match?(/\A[\w-]+\z/) ? [ "#{FEED_URL}?playlist_id=#{playlist_id}" ] : []
      when %r{\A/channel/(#{CHANNEL_ID})}
        [ channel_feed(Regexp.last_match(1)) ]
      else
        channel_id = channel_id_from_page(uri)
        channel_id ? [ channel_feed(channel_id) ] : []
      end
    end

    def channel_feed(channel_id)
      "#{FEED_URL}?channel_id=#{channel_id}"
    end

    # Handles (/@name), legacy /c/ and /user/ URLs and video pages don't
    # contain the channel ID, so read it from the page itself.
    def channel_id_from_page(uri)
      body = Http::SafeClient.get(page_url(uri), headers: PAGE_HEADERS).body.dup.force_encoding(Encoding::UTF_8).scrub
      body[%r{feeds/videos\.xml\?channel_id=(#{CHANNEL_ID})}, 1] ||
        body[/"channelId":"(#{CHANNEL_ID})"/, 1] ||
        body[/"externalId":"(#{CHANNEL_ID})"/, 1]
    rescue Http::SafeClient::Error
      nil
    end

    def page_url(uri)
      if uri.host == "youtu.be"
        "https://www.youtube.com/watch?v=#{uri.path.delete_prefix("/")[/\A[\w-]+/]}"
      else
        uri.dup.tap { |page| page.host = "www.youtube.com" }.to_s
      end
    end
  end
end
