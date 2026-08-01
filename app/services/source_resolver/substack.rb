class SourceResolver
  module Substack
    module_function

    def match?(uri)
      uri.host.end_with?(".substack.com")
    end

    def feed_urls(uri)
      [ "https://#{uri.host}/feed" ]
    end
  end
end
