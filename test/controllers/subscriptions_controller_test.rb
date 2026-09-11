require "test_helper"

class SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "index lists sources with their status" do
    get subscriptions_path
    assert_select "td strong", text: "Example Blog"
    assert_select "td strong", text: "Android videos"
  end

  test "new without a query shows what can be pasted" do
    get new_subscription_path
    assert_select ".tips"
  end

  test "new with a URL shows candidates with a preview" do
    stub_get "https://atom.example.com/feed.atom", fixture: "feeds/atom.xml"

    get new_subscription_path(url: "https://atom.example.com/feed.atom")

    assert_select ".candidate__title", "Atom Example"
    assert_select ".candidate__preview li", 2
    assert_select "input[name=feed_url][value='https://atom.example.com/feed.atom']"
  end

  test "new marks sources you already follow" do
    stub_get sources(:blog).url, fixture: "feeds/rss.xml"
    get new_subscription_path(url: sources(:blog).url)
    assert_select ".candidate__subscribed"
  end

  test "new explains when nothing was found or the address is invalid" do
    get new_subscription_path(url: "ftp://nope")
    assert_select ".notice--alert"

    stub_request(:get, /nofeed\.example/).to_return(status: 404)
    stub_get "https://nofeed.example/", fixture: "pages/no_feed.html", content_type: "text/html"
    get new_subscription_path(url: "https://nofeed.example/")
    assert_select ".notice", text: /No feed found/
  end

  test "create subscribes, fetches right away and can create a group" do
    stub_get "https://atom.example.com/feed.atom", fixture: "feeds/atom.xml"

    assert_difference -> { Source.count } => 1, -> { users(:one).subscriptions.count } => 1, -> { users(:one).groups.count } => 1 do
      post subscriptions_path, params: {
        feed_url: "https://atom.example.com/feed.atom", title: "Atom Example", new_group_name: "Reading", subscription: { custom_title: "" }
      }
    end

    subscription = users(:one).subscriptions.order(:id).last
    assert_redirected_to entries_path(subscription_id: subscription.id)
    assert_equal "Reading", subscription.group.name
    assert_equal "Atom Example", subscription.title
    assert_equal 2, subscription.user_entries.count
  end

  test "create reuses an existing shared source and backfills its entries" do
    sign_in_as users(:two)
    sources(:youtube).update!(last_fetched_at: 1.hour.ago)

    assert_no_difference -> { Source.count } do
      post subscriptions_path, params: { feed_url: sources(:youtube).url }
    end

    subscription = users(:two).subscriptions.find_by!(source: sources(:youtube))
    assert_equal [ entries(:video) ], subscription.user_entries.map(&:entry)
  end

  test "create twice is refused" do
    post subscriptions_path, params: { feed_url: sources(:blog).url }
    assert_redirected_to new_subscription_path(url: sources(:blog).url)
    assert_match "already", flash[:alert]
  end

  test "update changes title, group and mute" do
    patch subscription_path(subscriptions(:one_blog)), params: { subscription: { custom_title: "My blog", group_id: "", muted: "1" } }

    assert_redirected_to subscriptions_path
    subscription = subscriptions(:one_blog).reload
    assert_equal "My blog", subscription.title
    assert_nil subscription.group
    assert subscription.muted?
  end

  test "a subscription can't be moved into another user's group" do
    patch subscription_path(subscriptions(:one_blog)), params: { subscription: { group_id: groups(:other_users_group).id } }
    assert_not_equal groups(:other_users_group), subscriptions(:one_blog).reload.group
  end

  test "destroy unsubscribes and removes the user's copies of entries" do
    assert_difference -> { UserEntry.count } => -2 do
      delete subscription_path(subscriptions(:one_blog))
    end
    assert_redirected_to subscriptions_path
    assert Source.exists?(sources(:blog).id), "shared sources stay for other subscribers"
  end

  test "refresh fetches immediately" do
    stub_get sources(:blog).url, fixture: "feeds/rss.xml"

    post refresh_subscription_path(subscriptions(:one_blog))

    assert_redirected_to subscriptions_path
    assert_equal "Example Blog: 1 new entry.", flash[:notice]
  end

  test "refresh reports failures" do
    stub_request(:get, sources(:blog).url).to_return(status: 500)
    post refresh_subscription_path(subscriptions(:one_blog))
    assert_match "HTTP 500", flash[:alert]
  end

  test "another user's subscription is not found" do
    patch subscription_path(subscriptions(:two_blog)), params: { subscription: { custom_title: "x" } }
    assert_response :not_found
  end
end
