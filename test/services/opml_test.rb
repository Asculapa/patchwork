require "test_helper"

class OpmlTest < ActiveSupport::TestCase
  test "import creates sources, subscriptions and groups from folders" do
    user = users(:two)
    result = nil

    assert_enqueued_jobs 2, only: FetchSourceJob do
      result = Opml::Importer.new(user).call(file_fixture("subscriptions.opml").read)
    end

    assert_equal [ "Google for Developers", "Loose feed" ], result.added
    assert_equal [ "Example Blog" ], result.skipped
    assert_equal [ "Broken" ], result.failed

    tech = user.groups.find_by!(name: "Tech")
    assert_equal tech, user.subscriptions.find_by!(source: sources(:youtube)).group
    loose = user.subscriptions.joins(:source).find_by!(sources: { url: "https://loose.example.com/rss" })
    assert_nil loose.group
  end

  test "import rejects files without feeds or that aren't XML" do
    importer = Opml::Importer.new(users(:one))
    assert_raises(Opml::Importer::Invalid) { importer.call("<opml><body></body></opml>") }
    assert_raises(Opml::Importer::Invalid) { importer.call("not xml <") }
  end

  test "export writes groups as folders" do
    document = Nokogiri::XML(Opml::Exporter.new(users(:one)).call)

    assert_equal "https://example.com/feed.xml", document.at_xpath("//outline[@title='Tech']/outline")["xmlUrl"]
    assert_equal "Android videos", document.at_xpath("/opml/body/outline[@xmlUrl]")["title"]
  end
end
