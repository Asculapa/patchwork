require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "source_avatar marks PNG icons so dark mode can back them with white" do
    source = sources(:blog)
    source.icon_url = "https://example.com/icon.png?v=2"

    assert_match(/avatar--png/, source_avatar(source))
  end

  test "source_avatar leaves other image formats without the PNG class" do
    source = sources(:blog)
    source.icon_url = "https://example.com/icon.jpg"

    assert_no_match(/avatar--png/, source_avatar(source))
  end

  test "source_avatar falls back to a letter avatar without an icon" do
    source = sources(:blog)
    source.icon_url = nil

    assert_no_match(/avatar--png/, source_avatar(source))
    assert_match(/avatar--letter/, source_avatar(source))
  end
end
