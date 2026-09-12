require "test_helper"

class Turnstile::VerifierTest < ActiveSupport::TestCase
  test "verify is a no-op success when no secret key is configured" do
    assert Turnstile::Verifier.verify("any-token", remote_ip: "1.2.3.4")
  end

  test "verify fails without a token when a secret key is configured" do
    with_turnstile_secret do
      assert_not Turnstile::Verifier.verify(nil, remote_ip: "1.2.3.4")
      assert_not Turnstile::Verifier.verify("", remote_ip: "1.2.3.4")
    end
  end

  test "verify succeeds when Cloudflare reports success" do
    stub_request(:post, Turnstile::Verifier::VERIFY_URL).to_return(
      status: 200, body: { success: true }.to_json, headers: { "Content-Type" => "application/json" }
    )

    with_turnstile_secret do
      assert Turnstile::Verifier.verify("good-token", remote_ip: "1.2.3.4")
    end
  end

  test "verify fails when Cloudflare reports failure" do
    stub_request(:post, Turnstile::Verifier::VERIFY_URL).to_return(
      status: 200, body: { success: false }.to_json, headers: { "Content-Type" => "application/json" }
    )

    with_turnstile_secret do
      assert_not Turnstile::Verifier.verify("bad-token", remote_ip: "1.2.3.4")
    end
  end

  test "verify fails when the request errors" do
    stub_request(:post, Turnstile::Verifier::VERIFY_URL).to_timeout

    with_turnstile_secret do
      assert_not Turnstile::Verifier.verify("any-token", remote_ip: "1.2.3.4")
    end
  end

  private
    def with_turnstile_secret
      ENV["TURNSTILE_SECRET_KEY"] = "test-secret"
      yield
    ensure
      ENV.delete("TURNSTILE_SECRET_KEY")
    end
end
