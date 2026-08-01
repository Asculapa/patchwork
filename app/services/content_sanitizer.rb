# Allowlist sanitiser for HTML that comes from feeds. The output is safe to
# render as-is: no scripts, styles, iframes or event handlers; absolute links
# that open in a new tab; lazy images without referrers; no tracking pixels.
class ContentSanitizer
  TAGS = %w[
    a abbr b blockquote br caption cite code dd del details dfn div dl dt em figcaption figure
    h1 h2 h3 h4 h5 h6 hr i img ins kbd li mark ol p pre q s samp small span strong sub summary sup
    table tbody td tfoot th thead time tr u ul
  ].freeze
  ATTRIBUTES = %w[href src alt title width height colspan rowspan datetime cite].freeze
  DROP_WITH_CONTENT = %w[
    script style iframe noscript object embed form svg math template head title link meta
    button input select textarea audio video
  ].join(", ").freeze
  TRACKER = %r{\Ahttps?://(feeds\.feedburner\.com/~r/|pixel\.wp\.com/|stats\.wordpress\.com/|www\.google-analytics\.com/|medium\.com/_/stat)}

  def self.call(html, base_url: nil)
    new(base_url).sanitize(html)
  end

  # Plain text for excerpts and titles: tags stripped, entities decoded.
  def self.text(html)
    return "" if html.blank?

    # Views escape on output, so store decoded text ("AT&T", not "AT&amp;T").
    Loofah.html5_fragment(html.to_s).to_text(encode_special_chars: false).squish
  end

  def initialize(base_url)
    @base_url = base_url
  end

  def sanitize(html)
    return "" if html.blank?

    fragment = Loofah.html5_fragment(html.to_s)
    fragment.css(DROP_WITH_CONTENT).each(&:remove)
    fragment.scrub!(permit_scrubber)
    fragment.css("a").each { |link| rewrite_link(link) }
    fragment.css("img").each { |image| rewrite_image(image) }
    fragment.to_s.strip
  end

  private
    def permit_scrubber
      Rails::HTML::PermitScrubber.new.tap do |scrubber|
        scrubber.tags = TAGS
        scrubber.attributes = ATTRIBUTES
      end
    end

    def rewrite_link(link)
      href = UrlNormalizer.resolve(link["href"], base: @base_url)
      if href
        link["href"] = href
        link["rel"] = "noopener noreferrer nofollow"
        link["target"] = "_blank"
      else
        link.remove_attribute("href")
      end
    end

    def rewrite_image(image)
      src = UrlNormalizer.resolve(image["src"], base: @base_url)
      return image.remove if src.nil? || tracking_pixel?(image, src)

      image["src"] = src
      image["loading"] = "lazy"
      image["decoding"] = "async"
      image["referrerpolicy"] = "no-referrer"
    end

    def tracking_pixel?(image, src)
      src.match?(TRACKER) || %w[width height].all? { |size| image[size].present? && image[size].to_i <= 1 }
    end
end
