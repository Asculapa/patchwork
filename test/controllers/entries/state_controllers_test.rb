require "test_helper"

class Entries::StateControllersTest < ActionDispatch::IntegrationTest
  TURBO_STREAM = { "Accept" => "text/vnd.turbo-stream.html, text/html" }.freeze

  setup do
    sign_in_as users(:one)
  end

  test "star and unstar respond with Turbo Streams" do
    post entry_star_path(entries(:blog_new)), headers: TURBO_STREAM

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, %(target="user_entry_#{user_entries(:one_blog_new).id}")
    assert user_entries(:one_blog_new).reload.starred?

    delete entry_star_path(entries(:blog_new)), headers: TURBO_STREAM
    assert_not user_entries(:one_blog_new).reload.starred?
  end

  test "mark read and unread" do
    post entry_read_path(entries(:blog_new)), headers: TURBO_STREAM
    assert user_entries(:one_blog_new).reload.read?

    delete entry_read_path(entries(:blog_new)), headers: TURBO_STREAM
    assert_not user_entries(:one_blog_new).reload.read?
  end

  test "plain HTML requests redirect back" do
    post entry_star_path(entries(:blog_new))
    assert_redirected_to entry_path(entries(:blog_new))
  end

  test "cannot change entries of sources you don't follow" do
    entry = Entry.create!(source: sources(:orphan), guid: "x", title: "Nope", published_at: Time.current)
    post entry_star_path(entry)
    assert_response :not_found
  end
end
