# Turns user input and links found in feeds into absolute http(s) URLs.
module UrlNormalizer
  SCHEMES = %w[http https].freeze
  TRACKING_PARAM = /\A(utm_\w+|fbclid|gclid|dclid|msclkid|mc_cid|mc_eid|igshid|_hsenc|_hsmi|ref_src)\z/i

  module_function

  # Canonical form used to identify sources: lowercase host, no default port,
  # no fragment, no tracking parameters. Returns nil unless the result is an
  # absolute http(s) URL.
  def call(input, base: nil)
    uri = parse(input, base: base)
    return unless uri

    uri.fragment = nil
    uri.path = "/" if uri.path.empty?
    strip_tracking_params(uri)
    uri.to_s
  end

  # Absolute URL for a link inside content; the query is left untouched.
  def resolve(href, base: nil)
    parse(href, base: base)&.to_s
  end

  def parse(input, base: nil)
    string = input.to_s.strip
    return if string.empty?

    if base.nil?
      string = "https:#{string}" if string.start_with?("//")
      string = "https://#{string}" unless string.match?(%r{\A[a-z][a-z0-9+.-]*://}i)
    end

    uri = (base ? Addressable::URI.join(base, string) : Addressable::URI.parse(string)).normalize
    uri if SCHEMES.include?(uri.scheme) && uri.host.present?
  rescue Addressable::URI::InvalidURIError, TypeError, ArgumentError
    nil
  end

  def strip_tracking_params(uri)
    params = uri.query_values(Array)
    return if params.nil?

    kept = params.reject { |key, _| key.match?(TRACKING_PARAM) }
    return if kept.size == params.size

    if kept.empty?
      uri.query = nil
    else
      uri.query_values = kept
    end
  end
end
