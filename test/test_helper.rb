ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"
require_relative "test_helpers/session_test_helper"
require_relative "test_helpers/http_test_helper"

WebMock.disable_net_connect!(allow_localhost: true)

# Resolve host names to a public address so SSRF checks pass without real DNS
# (IP literals stay as they are); WebMock then intercepts the request itself.
Http::SafeClient.resolver = lambda do |host|
  [ IPAddr.new(host) ]
rescue IPAddr::InvalidAddressError
  [ IPAddr.new("93.184.215.14") ]
end

module ActiveSupport
  class TestCase
    include ActiveJob::TestHelper

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end
