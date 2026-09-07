require "test_helper"

class Groups::CollapsesControllerTest < ActionDispatch::IntegrationTest
  TURBO_STREAM = { "Accept" => "text/vnd.turbo-stream.html, text/html" }.freeze

  setup do
    sign_in_as users(:one)
  end

  test "collapse and expand a group" do
    post group_collapse_path(groups(:tech)), headers: TURBO_STREAM

    assert_response :success
    assert_includes response.body, %(target="sidebar")
    assert groups(:tech).reload.collapsed?

    delete group_collapse_path(groups(:tech)), headers: TURBO_STREAM
    assert_not groups(:tech).reload.collapsed?
  end

  test "a collapsed group renders collapsed" do
    groups(:tech).update!(collapsed: true)
    get entries_path

    assert_select "[data-sortable-group].is-collapsed" do
      assert_select "button.nav-link--group[aria-expanded=false]"
      assert_select ".nav__sources .nav-link--source", 1
    end
  end

  test "can't collapse another user's group" do
    post group_collapse_path(groups(:other_users_group)), headers: TURBO_STREAM
    assert_response :not_found
  end

  test "collapse and expand the ungrouped sources" do
    post ungrouped_collapse_path, headers: TURBO_STREAM

    assert_response :success
    assert_includes response.body, %(target="sidebar")
    assert users(:one).reload.ungrouped_collapsed?

    get entries_path
    assert_select ".nav__section.is-collapsed button.nav__heading[aria-expanded=false] .nav-link__label", "Other"

    delete ungrouped_collapse_path, headers: TURBO_STREAM
    assert_not users(:one).reload.ungrouped_collapsed?
  end
end
