require "test_helper"

class GroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "index" do
    get groups_path
    assert_select ".list__title", "Tech"
  end

  test "create" do
    assert_difference -> { users(:one).groups.count } do
      post groups_path, params: { group: { name: "  Videos  " } }
    end
    assert_redirected_to groups_path
    assert users(:one).groups.exists?(name: "Videos")
  end

  test "names are unique per user, ignoring case" do
    post groups_path, params: { group: { name: "tech" } }
    assert_response :unprocessable_entity

    sign_in_as users(:two)
    post groups_path, params: { group: { name: "Tech" } }
    assert_redirected_to groups_path
  end

  test "rename" do
    patch group_path(groups(:tech)), params: { group: { name: "Engineering" } }
    assert_redirected_to groups_path
    assert_equal "Engineering", groups(:tech).reload.name
  end

  test "destroy keeps the sources, ungrouped" do
    delete group_path(groups(:tech))
    assert_redirected_to groups_path
    assert_nil subscriptions(:one_blog).reload.group
  end

  test "another user's group is not found" do
    delete group_path(groups(:other_users_group))
    assert_response :not_found
  end
end
