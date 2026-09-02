require "test_helper"

class PushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "test sends a push to the caller's own subscription" do
    subscription = create_push_subscription!(users(:one))
    stub_request(:post, subscription.endpoint).to_return(status: 201)

    post test_push_subscriptions_path, params: { endpoint: subscription.endpoint }, as: :json

    assert_response :no_content
    assert_requested :post, subscription.endpoint
  end

  test "test returns not found for an endpoint the user hasn't registered" do
    post test_push_subscriptions_path, params: { endpoint: "https://example.com/unknown" }, as: :json

    assert_response :not_found
  end

  test "test destroys the subscription and reports failure when it's gone" do
    subscription = create_push_subscription!(users(:one))
    stub_request(:post, subscription.endpoint).to_return(status: 410)

    post test_push_subscriptions_path, params: { endpoint: subscription.endpoint }, as: :json

    assert_response :unprocessable_entity
    assert_nil PushSubscription.find_by(id: subscription.id)
  end

  private
    def create_push_subscription!(user)
      group = OpenSSL::PKey::EC.generate("prime256v1")

      user.push_subscriptions.create!(
        endpoint: "https://push.example.com/#{SecureRandom.hex(8)}",
        p256dh_key: Base64.urlsafe_encode64(group.public_key.to_bn.to_s(2), padding: false),
        auth_key: Base64.urlsafe_encode64(SecureRandom.random_bytes(16), padding: false)
      )
    end
end
