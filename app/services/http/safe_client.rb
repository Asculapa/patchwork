module Http
  # The only way Patchwork talks to other servers. Every URL comes from a user,
  # so each hop is checked against private networks (SSRF), redirects are
  # followed here (max 5) so the final and permanent URLs are known, and
  # response bodies are capped.
  class SafeClient
    class Error < StandardError; end
    class Blocked < Error; end
    class TooLarge < Error; end

    Response = Data.define(:status, :headers, :body, :url, :permanent_url) do
      def success? = status.between?(200, 299)
      def not_modified? = status == 304
      def [](name) = headers[name.to_s.downcase]
    end

    MAX_REDIRECTS = 5
    MAX_BODY_SIZE = 5.megabytes
    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 15
    ACCEPT = "application/rss+xml, application/atom+xml, application/feed+json, application/xml;q=0.9, " \
      "text/xml;q=0.9, text/html;q=0.8, */*;q=0.5"
    NETWORK_ERRORS = [
      SocketError, SystemCallError, IOError, Timeout::Error, OpenSSL::SSL::SSLError,
      Net::HTTPBadResponse, Net::ProtocolError, Zlib::Error
    ].freeze

    # Tests swap this for a stub so no real DNS lookups happen.
    class_attribute :resolver, default: nil

    def self.get(url, headers: {})
      new.get(url, headers: headers)
    end

    def get(url, headers: {})
      current_url = url.to_s
      permanent_url = nil
      permanent_chain = true

      (MAX_REDIRECTS + 1).times do
        response, body = request(current_url, headers)
        location = response["location"] if response.is_a?(Net::HTTPRedirection)

        if location.blank?
          return Response.new(
            status: response.code.to_i, body: body, url: current_url, permanent_url: permanent_url,
            headers: response.to_hash.transform_values { |values| values.join(", ") }
          )
        end

        current_url = URI.join(current_url, location).to_s
        permanent_chain &&= response.code.in?(%w[301 308])
        permanent_url = current_url if permanent_chain
      end

      raise Error, "Too many redirects"
    rescue SsrfFilter::PrivateIPAddress, SsrfFilter::InvalidUriScheme, SsrfFilter::CRLFInjection => error
      raise Blocked, error.message
    rescue SsrfFilter::Error, URI::InvalidURIError, *NETWORK_ERRORS => error
      raise Error, error.message
    end

    private
      def request(url, headers)
        body = String.new(encoding: Encoding::BINARY)
        options = {
          headers: { "User-Agent" => Rails.configuration.x.user_agent, "Accept" => ACCEPT }.merge(headers),
          max_redirects: 0,
          allow_unfollowed_redirects: true,
          http_options: { open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT }
        }
        options[:resolver] = resolver if resolver

        response = SsrfFilter.get(url, options) do |streamed|
          streamed.read_body do |chunk|
            body << chunk
            raise TooLarge, "Response is larger than #{MAX_BODY_SIZE / 1.megabyte} MB" if body.bytesize > MAX_BODY_SIZE
          end
        end

        [ response, body ]
      end
  end
end
