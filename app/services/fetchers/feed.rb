module Fetchers
  # Polls RSS / Atom / JSON Feed URLs (including YouTube's feeds) with
  # conditional requests (FR-6.1 – FR-6.5).
  class Feed < Base
    def fetch
      response = Http::SafeClient.get(source.url, headers: conditional_headers)
      return not_modified(response) if response.not_modified?
      raise Gone, "The feed no longer exists (HTTP 410)" if response.status == 410
      raise Error, "The server answered with HTTP #{response.status}" unless response.success?

      document = FeedDocument.parse(response.body, url: response.url)
      Result.new(
        entries: document.entries,
        etag: response["etag"],
        last_modified: response["last-modified"],
        title: document.title,
        site_url: document.site_url,
        icon_url: document.icon_url,
        description: document.description,
        permanent_url: response.permanent_url,
        min_interval: [ document.min_interval.to_i, header_min_interval(response) ].max,
        http_status: response.status
      )
    rescue Http::SafeClient::Error, FeedDocument::Invalid => error
      raise Error, error.message
    end

    private
      def conditional_headers
        { "If-None-Match" => source.etag, "If-Modified-Since" => source.last_modified }.compact
      end

      def not_modified(response)
        Result.new(not_modified: true, etag: response["etag"], min_interval: header_min_interval(response), http_status: 304)
      end

      # Honour Retry-After and Cache-Control max-age as lower bounds for the interval.
      def header_min_interval(response)
        retry_after = response["retry-after"].to_s
        return retry_after.to_i if retry_after.match?(/\A\d+\z/)

        response["cache-control"].to_s[/max-age=(\d+)/, 1].to_i
      end
  end
end
