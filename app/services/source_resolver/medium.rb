class SourceResolver
  # medium.com/@author, publications, tags and author subdomains all have feeds.
  module Medium
    module_function

    def match?(uri)
      uri.host == "medium.com" || uri.host.end_with?(".medium.com")
    end

    def feed_urls(uri)
      return [ "https://#{uri.host}/feed" ] unless uri.host == "medium.com"

      first, second = uri.path.split("/").compact_blank
      case first
      when nil then []
      when "feed" then [ uri.to_s ]
      when "tag" then second ? [ "https://medium.com/feed/tag/#{second}" ] : []
      else [ "https://medium.com/feed/#{first}" ]
      end
    end
  end
end
