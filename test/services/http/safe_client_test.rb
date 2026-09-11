require "test_helper"

class Http::SafeClientTest < ActiveSupport::TestCase
  test "returns status, body and headers" do
    stub_request(:get, "https://example.com/feed").to_return(body: "hello", headers: { "ETag" => '"abc"' })

    response = Http::SafeClient.get("https://example.com/feed")

    assert response.success?
    assert_equal "hello", response.body
    assert_equal '"abc"', response["etag"]
    assert_nil response.permanent_url
  end

  test "sends a descriptive user agent" do
    stub_request(:get, "https://example.com/feed").with(headers: { "User-Agent" => /\APatchwork/ })
    assert Http::SafeClient.get("https://example.com/feed").success?
  end

  test "follows redirects and remembers permanent moves" do
    stub_request(:get, "https://example.com/old").to_return(status: 301, headers: { "Location" => "/new" })
    stub_request(:get, "https://example.com/new").to_return(body: "moved")

    response = Http::SafeClient.get("https://example.com/old")

    assert_equal "moved", response.body
    assert_equal "https://example.com/new", response.url
    assert_equal "https://example.com/new", response.permanent_url
  end

  test "temporary redirects are followed but not remembered" do
    stub_request(:get, "https://example.com/old").to_return(status: 302, headers: { "Location" => "https://example.com/new" })
    stub_request(:get, "https://example.com/new").to_return(body: "moved")

    response = Http::SafeClient.get("https://example.com/old")

    assert_equal "https://example.com/new", response.url
    assert_nil response.permanent_url
  end

  test "gives up after too many redirects" do
    stub_request(:get, "https://example.com/loop").to_return(status: 302, headers: { "Location" => "https://example.com/loop" })
    assert_raises(Http::SafeClient::Error) { Http::SafeClient.get("https://example.com/loop") }
  end

  test "blocks private network addresses" do
    with_resolver(->(_host) { [ IPAddr.new("127.0.0.1") ] }) do
      assert_raises(Http::SafeClient::Blocked) { Http::SafeClient.get("http://internal.example/") }
    end
    with_resolver(->(_host) { [ IPAddr.new("169.254.169.254") ] }) do
      assert_raises(Http::SafeClient::Blocked) { Http::SafeClient.get("http://metadata.example/") }
    end
  end

  test "blocks redirects into private networks" do
    stub_request(:get, "https://example.com/sneaky").to_return(status: 302, headers: { "Location" => "http://10.0.0.1/admin" })
    assert_raises(Http::SafeClient::Blocked) { Http::SafeClient.get("https://example.com/sneaky") }
  end

  test "blocks non-http schemes" do
    assert_raises(Http::SafeClient::Blocked) { Http::SafeClient.get("file:///etc/passwd") }
  end

  test "caps the response size" do
    stub_request(:get, "https://example.com/huge").to_return(body: "x" * (Http::SafeClient::MAX_BODY_SIZE + 1))
    assert_raises(Http::SafeClient::TooLarge) { Http::SafeClient.get("https://example.com/huge") }
  end

  test "network failures raise Http::SafeClient::Error" do
    stub_request(:get, "https://example.com/down").to_timeout
    assert_raises(Http::SafeClient::Error) { Http::SafeClient.get("https://example.com/down") }
  end
end
