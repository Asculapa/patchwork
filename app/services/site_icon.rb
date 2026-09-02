# Falls back to a page's favicon when its feed doesn't publish one of its
# own (most YouTube and plain blog feeds). Scrapes the page's <link rel=icon>
# / <meta property=og:image> tags and checks the result actually loads, since
# a guessed URL (e.g. the /favicon.ico convention) commonly 404s.
class SiteIcon
  LINK_SELECTOR = "link[rel~=icon][href], link[rel~=apple-touch-icon][href]"

  def self.fetch(page_url, prefer_social_image: false)
    new(page_url).fetch(prefer_social_image: prefer_social_image)
  end

  def initialize(page_url)
    @page_url = page_url
  end

  # YouTube channel pages have no favicon worth showing (just YouTube's own),
  # but their og:image is the channel's real avatar -- so callers ask for
  # that first there. Ordinary sites are the opposite: favicons are made for
  # this, while a homepage's og:image is often just a generic banner.
  def fetch(prefer_social_image: false)
    document = Nokogiri::HTML5(Http::SafeClient.get(@page_url).body)
    candidates = prefer_social_image ? [ social_image(document), *icon_links(document) ] : [ *icon_links(document), social_image(document) ]
    (candidates.compact.uniq + [ default_favicon ]).find { |url| reachable?(url) }
  rescue Http::SafeClient::Error
    nil
  end

  private
    def icon_links(document)
      document.css(LINK_SELECTOR).filter_map { |link| UrlNormalizer.resolve(link["href"], base: @page_url) }
    end

    def social_image(document)
      href = document.at_css('meta[property="og:image"]')&.[]("content")
      UrlNormalizer.resolve(href, base: @page_url)
    end

    def default_favicon
      UrlNormalizer.resolve("/favicon.ico", base: @page_url)
    end

    def reachable?(url)
      url.present? && Http::SafeClient.get(url).success?
    rescue Http::SafeClient::Error
      false
    end
end
