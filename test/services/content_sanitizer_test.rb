require "test_helper"

class ContentSanitizerTest < ActiveSupport::TestCase
  test "removes scripts, iframes, styles and event handlers" do
    html = ContentSanitizer.call(
      %(<p onclick="x()" style="color:red">Hi</p><script>alert(1)</script><iframe src="https://e.com"></iframe><style>p{}</style>),
      base_url: "https://example.com/"
    )
    assert_equal "<p>Hi</p>", html
  end

  test "makes links absolute, opens them in a new tab and drops unsafe ones" do
    html = ContentSanitizer.call(%(<a href="/about">About</a> <a href="javascript:alert(1)">bad</a>), base_url: "https://example.com/post")

    assert_includes html, %(href="https://example.com/about")
    assert_includes html, %(rel="noopener noreferrer nofollow")
    assert_includes html, %(target="_blank")
    assert_not_includes html, "javascript"
    assert_includes html, "bad"
  end

  test "lazy-loads images without referrer and drops tracking pixels" do
    html = ContentSanitizer.call(
      %(<img src="/a.png"><img src="https://example.com/p.gif" width="1" height="1"><img src="https://feeds.feedburner.com/~r/x/~4/y">),
      base_url: "https://example.com/"
    )

    assert_includes html, %(src="https://example.com/a.png")
    assert_includes html, %(loading="lazy")
    assert_includes html, %(referrerpolicy="no-referrer")
    assert_equal 1, html.scan("<img").size
  end

  test "text strips tags and decodes entities" do
    assert_equal "AT&T rocks", ContentSanitizer.text("<b>AT&amp;T</b>   rocks")
    assert_equal "", ContentSanitizer.text(nil)
  end
end
