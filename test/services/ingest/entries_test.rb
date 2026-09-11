require "test_helper"

class Ingest::EntriesTest < ActiveSupport::TestCase
  setup do
    @source = sources(:blog)
  end

  test "stores new entries and gives every subscriber an unread copy" do
    assert_difference -> { Entry.count } => 1, -> { UserEntry.count } => 2 do
      assert_equal 1, Ingest::Entries.call(@source, [ normalized("post-3") ])
    end

    entry = @source.entries.find_by!(guid: "post-3")
    assert_equal [ users(:one).id, users(:two).id ].sort, entry.user_entries.pluck(:user_id).sort
    assert entry.user_entries.all? { |user_entry| user_entry.read_at.nil? }
  end

  test "re-ingesting updates edited entries without creating new ones" do
    assert_no_difference -> { UserEntry.count } do
      assert_equal 0, Ingest::Entries.call(@source, [ normalized("post-2", title: "Edited title") ])
    end
    assert_equal "Edited title", entries(:blog_new).reload.title
  end

  test "keeps read state of entries that are already known" do
    Ingest::Entries.call(@source, [ normalized("post-1") ])
    assert user_entries(:one_blog_old).reload.read?
  end

  test "duplicate guids in one batch are stored once" do
    assert_difference -> { Entry.count } => 1 do
      Ingest::Entries.call(@source, [ normalized("dup"), normalized("dup") ])
    end
  end

  private
    def normalized(guid, **attributes)
      NormalizedEntry.new(**{
        guid: guid, url: "https://example.com/#{guid.parameterize}", title: guid.titleize, author: nil, summary: "",
        content_html: "", image_url: nil, published_at: 1.hour.ago, media: {}, fingerprint: nil
      }.merge(attributes))
    end
end
