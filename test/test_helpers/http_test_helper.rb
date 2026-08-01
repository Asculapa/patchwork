module HttpTestHelper
  def stub_get(url, fixture: nil, body: nil, status: 200, content_type: "application/xml", headers: {})
    body ||= file_fixture(fixture).read if fixture
    stub_request(:get, url).to_return(status: status, body: body.to_s, headers: { "Content-Type" => content_type }.merge(headers))
  end

  def with_resolver(resolver)
    original = Http::SafeClient.resolver
    Http::SafeClient.resolver = resolver
    yield
  ensure
    Http::SafeClient.resolver = original
  end
end

ActiveSupport.on_load(:active_support_test_case) do
  include HttpTestHelper
end
