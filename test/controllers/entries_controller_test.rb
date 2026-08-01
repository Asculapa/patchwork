require "test_helper"

class EntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "requires sign in" do
    sign_out
    get root_path
    assert_redirected_to new_session_path
  end

  test "today shows recent unread entries grouped by group and source" do
    get root_path

    assert_response :success
    assert_select ".today-group__title", text: "Tech"
    assert_select ".today-source__title", text: /Android videos/
    assert_select ".entry__title", text: "Second post"
    assert_select ".entry__title", text: "What's new in Android"
    assert_select ".entry__title", text: "First post", count: 0
  end

  test "starred and all views" do
    get entries_path(view: "starred")
    assert_select ".entry__title", count: 1, text: "What's new in Android"

    get entries_path(view: "all")
    assert_select ".entry__title", count: 3
  end

  test "muted sources are hidden from global views but not from their own page" do
    subscriptions(:one_youtube).update!(muted: true)

    get entries_path(view: "unread")
    assert_select ".entry__title", text: "What's new in Android", count: 0

    get entries_path(subscription_id: subscriptions(:one_youtube).id)
    assert_select ".entry__title", text: "What's new in Android"
  end

  test "group view shows the group's unread entries" do
    get entries_path(group_id: groups(:tech).id)
    assert_select ".entry__title", count: 1, text: "Second post"
  end

  test "another user's group or source is not found" do
    get entries_path(group_id: groups(:other_users_group).id)
    assert_response :not_found

    get entries_path(subscription_id: subscriptions(:two_blog).id)
    assert_response :not_found
  end

  test "long lists load further pages in a lazy Turbo Frame" do
    now = Time.current
    Entry.insert_all(60.times.map { |i|
      { source_id: sources(:blog).id, guid: "bulk-#{i}", title: "Bulk #{i}", media: {}, published_at: now - 1.day - i.minutes }
    })
    UserEntry.insert_all(Entry.where("guid LIKE 'bulk-%'").pluck(:id, :published_at).map { |id, published_at|
      { user_id: users(:one).id, entry_id: id, subscription_id: subscriptions(:one_blog).id, published_at: published_at }
    })

    get entries_path(view: "all")
    assert_select ".entry", 50
    frame = css_select("turbo-frame.entry-list__more").first

    get frame["src"], headers: { "Turbo-Frame" => frame["id"] }
    assert_select "turbo-frame##{frame["id"]} .entry", 13
  end

  test "show marks the entry as read and embeds YouTube videos" do
    get entry_path(entries(:video))

    assert_response :success
    assert user_entries(:one_video).reload.read?
    assert_select "iframe[src='https://www.youtube-nocookie.com/embed/abcDEF12345']"
  end

  test "show renders stored content through the sanitiser again" do
    entries(:blog_new).update!(content_html: %(<p>Safe</p><script>alert(1)</script>))

    get entry_path(entries(:blog_new))

    assert_select ".prose p", "Safe"
    assert_select ".prose script", count: 0
  end

  test "show of an entry from a source you don't follow is not found" do
    entry = Entry.create!(source: sources(:orphan), guid: "x", title: "Nope", published_at: Time.current)
    get entry_path(entry)
    assert_response :not_found
  end

  test "mark all read only touches the current view" do
    post mark_all_read_entries_path, params: { group_id: groups(:tech).id }

    assert_redirected_to entries_path(group_id: groups(:tech).id)
    assert user_entries(:one_blog_new).reload.read?
    assert_not user_entries(:one_video).reload.read?
    assert_not user_entries(:two_blog_new).reload.read?
  end

  test "mark all read older than a day" do
    user_entries(:one_blog_old).update!(read_at: nil)

    post mark_all_read_entries_path, params: { view: "unread", older_than: "day" }

    assert user_entries(:one_blog_old).reload.read?
    assert_not user_entries(:one_blog_new).reload.read?
  end
end
