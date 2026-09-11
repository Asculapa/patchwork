# Turns whatever the user pasted (a site, a channel, a feed, "@handle") into
# feed candidates they can subscribe to (FR-2.1 – FR-2.2). Tries site-specific
# rules first, then the URL itself, then HTML autodiscovery, then common paths.
class SourceResolver
  class Error < StandardError; end

  Candidate = Data.define(:kind, :url, :title, :site_url, :entries)

  FEED_TYPES = %w[
    application/rss+xml application/atom+xml application/feed+json application/json application/xml text/xml
  ].freeze
  COMMON_PATHS = %w[feed rss rss.xml atom.xml feed.xml index.xml].freeze
  MAX_DISCOVERED = 3
  PREVIEW_SIZE = 5

  def self.call(input)
    new(input).call
  end

  def initialize(input)
    @input = input.to_s.strip
  end

  # Returns an array of candidates (empty when no feed was found).
  def call
    url = normalize_input(@input) or raise Error, "That doesn't look like a web address."

    candidates = specialist_candidates(Addressable::URI.parse(url))
    return candidates if candidates.any?

    response = fetch(url)
    if (candidate = candidate_from(response, url))
      [ candidate ]
    else
      discover(response).presence || probe_common_paths(response.url)
    end
  end

  private
    def specialists
      [ YouTube, Medium, Substack, Reddit ]
    end

    def normalize_input(input)
      input = "https://www.youtube.com/#{input}" if input.match?(/\A@[\w.-]+\z/)
      UrlNormalizer.call(input)
    end

    def specialist_candidates(uri)
      specialist = specialists.find { |rule| rule.match?(uri) }
      return [] unless specialist

      specialist.feed_urls(uri).filter_map { |feed_url| verify(feed_url) }
    end

    def fetch(url)
      Http::SafeClient.get(url)
    rescue Http::SafeClient::Blocked
      raise Error, "Patchwork can't fetch addresses on private or local networks."
    rescue Http::SafeClient::Error => error
      raise Error, "Couldn't reach #{Addressable::URI.parse(url).host}: #{error.message}"
    end

    def verify(url)
      candidate_from(Http::SafeClient.get(url), url)
    rescue Http::SafeClient::Error
      nil
    end

    def candidate_from(response, requested_url)
      return unless response.success?

      document = FeedDocument.parse(response.body, url: response.url)
      feed_url = UrlNormalizer.call(response.permanent_url || requested_url)
      Candidate.new(
        kind: Source.kind_for_url(feed_url),
        url: feed_url,
        title: document.title.presence || Addressable::URI.parse(feed_url).host,
        site_url: document.site_url,
        entries: document.entries.first(PREVIEW_SIZE)
      )
    rescue FeedDocument::Invalid
      nil
    end

    # <link rel="alternate" type="application/rss+xml" href="…"> in the page head.
    def discover(response)
      return [] unless response.success?

      links = Nokogiri::HTML5(response.body).css("link[rel~=alternate][href]").select do |link|
        FEED_TYPES.include?(link["type"].to_s.downcase.strip)
      end
      feeds, comment_feeds = links.partition { |link| !link["title"].to_s.match?(/comment/i) }

      (feeds + comment_feeds)
        .filter_map { |link| UrlNormalizer.call(link["href"], base: response.url) }
        .uniq.first(MAX_DISCOVERED)
        .filter_map { |feed_url| verify(feed_url) }
    end

    def probe_common_paths(page_url)
      page = Addressable::URI.parse(page_url).omit(:query, :fragment)
      urls = COMMON_PATHS.map { |path| page.join("/#{path}") }
      unless page.path.in?([ "", "/" ])
        directory = page.path.end_with?("/") ? page : page.join("#{page.path}/")
        urls += %w[feed rss].map { |path| directory.join(path) }
      end

      urls.map(&:to_s).uniq.each do |url|
        candidate = verify(url)
        return [ candidate ] if candidate
      end
      []
    end
end
