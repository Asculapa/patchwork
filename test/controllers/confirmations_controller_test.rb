require "test_helper"

class ConfirmationsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take.tap { |user| user.update!(confirmed_at: nil) } }

  test "new" do
    get new_confirmation_path
    assert_response :success
  end

  test "create resends the confirmation email for an unconfirmed user" do
    post confirmations_path, params: { email_address: @user.email_address }
    assert_enqueued_email_with ConfirmationsMailer, :confirm, args: [ @user ]
    assert_redirected_to new_session_path
  end

  test "create does not resend for an already confirmed user" do
    @user.confirm!
    post confirmations_path, params: { email_address: @user.email_address }
    assert_enqueued_emails 0
  end

  test "create for an unknown user redirects but sends no mail" do
    post confirmations_path, params: { email_address: "missing-user@example.com" }
    assert_enqueued_emails 0
    assert_redirected_to new_session_path
  end

  test "show confirms the user and signs them in" do
    token = @user.generate_token_for(:email_confirmation)

    get confirmation_path(token)

    assert_redirected_to root_path
    assert @user.reload.confirmed?
    assert cookies[:session_id].present?
  end

  test "show with an invalid token" do
    get confirmation_path("invalid-token")

    assert_redirected_to new_confirmation_path
    assert_not @user.reload.confirmed?
  end
end
