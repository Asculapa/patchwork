# A parsed RSS / Atom / JSON Feed, reduced to what Patchwork stores.
class FeedDocument
  class Invalid < StandardError; end

  # RSS enclosures are also podcasts and videos; only real images make thumbnails.
  MEDIA_FILE = /\.(mp3|m4a|aac|ogg|oga|opus|wav|mp4|m4v|mov|webm)(\?|\z)/i

  attr_reader :title, :site_url, :icon_url, :description, :entries, :min_interval

  def self.parse(body, url:)
    new(body, url)
  end

  def initialize(body, url)
    @url = url
    feed = parse_feed(body)

    @title = text(feed.title)
    @site_url = UrlNormalizer.resolve(feed.url, base: url)
    @description = text(feed.try(:description)).truncate(500)
    @icon_url = UrlNormalizer.resolve(feed.try(:icon).presence || feed.try(:favicon).presence || feed.try(:image).try(:url), base: url)
    @min_interval = feed.try(:ttl).to_i.minutes if feed.try(:ttl).to_i.positive?
    @entries = feed.entries.map { |entry| normalize(entry) }

    raise Invalid, "The feed is empty" if @title.blank? && @entries.empty?
  end

  private
    def parse_feed(body)
      raise Invalid, "This is a web page, not a feed" if html?(body)

      Feedjira.parse(body)
    rescue Feedjira::NoParserAvailable
      raise Invalid, "Not a valid RSS, Atom or JSON feed"
    rescue StandardError => error
      raise error if error.is_a?(Invalid)
      raise Invalid, "The feed couldn't be parsed (#{error.class})"
    end

    def html?(body)
      head = body.to_s.byteslice(0, 2048).b.sub(/\A(\xEF\xBB\xBF)?(\s|<\?xml[^>]*>|<!--.*?-->)*/mn, "")
      head.match?(/\A<(!doctype html|html)/in)
    end

    def base_url
      @site_url || @url
    end

    def normalize(entry)
      video_id = entry.try(:youtube_video_id).presence
      url = UrlNormalizer.resolve(entry.url.presence || entry.try(:external_url), base: base_url)
      raw_content = entry.try(:content).presence || entry.try(:summary).presence
      content_html = video_id ? plain_text_to_html(raw_content) : ContentSanitizer.call(raw_content, base_url: url || base_url)
      title = text(entry.title).presence || ContentSanitizer.text(content_html).truncate(80).presence || "Untitled"

      NormalizedEntry.new(
        guid: entry.entry_id.to_s.strip.presence || url || Digest::SHA256.hexdigest([ title, raw_content ].join("|")),
        url: url,
        title: title.truncate(500),
        author: text(entry.try(:author)).presence,
        summary: ContentSanitizer.text(content_html).truncate(300),
        content_html: content_html,
        image_url: image_for(entry, content_html),
        published_at: published_at(entry),
        media: video_id ? { "video_id" => video_id, "channel_id" => entry.try(:youtube_channel_id) }.compact : {},
        fingerprint: video_id ? "yt:video:#{video_id}" : url
      )
    end

    def published_at(entry)
      time = entry.published || entry.try(:updated)
      time = time.in_time_zone if time.respond_to?(:in_time_zone)
      time && time < Time.current ? time : Time.current
    end

    def image_for(entry, content_html)
      image = [ entry.try(:image), entry.try(:media_thumbnail_url), entry.try(:banner_image) ].find { |value| value.is_a?(String) && value.present? && !value.match?(MEDIA_FILE) }
      image ||= entry.try(:enclosure_url) if entry.try(:enclosure_type).to_s.start_with?("image/")
      image ||= Nokogiri::HTML5.fragment(content_html).at_css("img")&.[]("src") if content_html.present?
      UrlNormalizer.resolve(image, base: base_url)
    end

    # YouTube descriptions are plain text; keep paragraphs and make links clickable.
    def plain_text_to_html(text)
      return "" if text.blank?

      escaped = ERB::Util.html_escape(text.to_s.strip)
      linked = escaped.gsub(%r{https?://[^\s<]+}) { |link| %(<a href="#{link}">#{link}</a>) }
      ContentSanitizer.call(linked.split(/\n{2,}/).map { |paragraph| "<p>#{paragraph.gsub("\n", "<br>")}</p>" }.join)
    end

    def text(value)
      ContentSanitizer.text(value.to_s)
    end
end
