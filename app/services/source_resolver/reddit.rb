class SourceResolver
  # Subreddits and users: /r/name → /r/name/.rss
  module Reddit
    HOSTS = %w[reddit.com www.reddit.com old.reddit.com new.reddit.com].freeze

    module_function

    def match?(uri)
      HOSTS.include?(uri.host)
    end

    def feed_urls(uri)
      return [ uri.to_s ] if uri.path.end_with?(".rss")

      kind, name = uri.path.split("/").compact_blank
      kind = "user" if kind == "u"
      return [] unless kind.in?(%w[r user]) && name.to_s.match?(/\A[\w-]+\z/)

      [ "https://www.reddit.com/#{kind}/#{name}/.rss" ]
    end
  end
end
