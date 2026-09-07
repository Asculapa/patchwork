require "test_helper"

class PositionsControllersTest < ActionDispatch::IntegrationTest
  TURBO_STREAM = { "Accept" => "text/vnd.turbo-stream.html, text/html" }.freeze

  setup do
    sign_in_as users(:one)
    @videos = users(:one).groups.create!(name: "Videos")
  end

  test "groups are listed alphabetically until arranged" do
    assert_equal %w[Tech Videos], users(:one).groups.ordered.map(&:name)
  end

  test "move a group" do
    patch group_position_path(@videos), params: { position: 0 }, headers: TURBO_STREAM

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, %(target="sidebar")
    assert_equal %w[Videos Tech], users(:one).groups.ordered.map(&:name)
  end

  test "new groups follow arranged ones" do
    patch group_position_path(@videos), params: { position: 0 }, headers: TURBO_STREAM
    users(:one).groups.create!(name: "Art")

    assert_equal %w[Videos Tech Art], users(:one).groups.ordered.map(&:name)
  end

  test "move a source into another group" do
    patch subscription_position_path(subscriptions(:one_youtube)), params: { position: 0, group_id: groups(:tech).id }, headers: TURBO_STREAM

    assert_response :success
    assert_equal groups(:tech), subscriptions(:one_youtube).reload.group
    assert_equal [ subscriptions(:one_youtube), subscriptions(:one_blog) ], users(:one).subscriptions.where(group: groups(:tech)).ordered.to_a
  end

  test "move a source out of its group" do
    patch subscription_position_path(subscriptions(:one_blog)), params: { position: 5, group_id: "" }, headers: TURBO_STREAM

    assert_nil subscriptions(:one_blog).reload.group
    assert_equal [ subscriptions(:one_youtube), subscriptions(:one_blog) ], users(:one).subscriptions.where(group: nil).ordered.to_a
  end

  test "can't move into or reorder another user's items" do
    patch subscription_position_path(subscriptions(:one_blog)), params: { position: 0, group_id: groups(:other_users_group).id }, headers: TURBO_STREAM
    assert_response :not_found
    assert_equal groups(:tech), subscriptions(:one_blog).reload.group

    patch group_position_path(groups(:other_users_group)), params: { position: 0 }, headers: TURBO_STREAM
    assert_response :not_found
  end

  test "sidebar follows the arranged order" do
    patch group_position_path(@videos), params: { position: 0 }
    get entries_path

    assert_select "[data-sortable-group] .nav-link--group .nav-link__label" do |labels|
      assert_equal %w[Videos Tech], labels.map(&:text)
    end
  end
end
