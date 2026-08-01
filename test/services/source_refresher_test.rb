require "test_helper"

class SourceRefresherTest < ActiveSupport::TestCase
  setup do
    @source = sources(:blog)
    @source.update!(etag: '"v1"', fetch_interval: 1.hour.to_i)
  end

  test "ingests new entries, stores the ETag and honours the feed's ttl" do
    stub_get @source.url, fixture: "feeds/rss.xml", headers: { "ETag" => '"v2"' }

    assert_equal 1, SourceRefresher.call(@source)

    @source.reload
    assert_equal '"v2"', @source.etag
    assert_equal 2.hours.to_i, @source.fetch_interval, "new entries halve the interval, but ttl=120 is a lower bound"
    assert_in_delta 2.hours.from_now, @source.next_fetch_at, 5.seconds
    assert @source.active?
    assert_equal "ok", @source.fetch_logs.last.status
  end

  test "sends conditional headers and backs off gently on 304" do
    stub_request(:get, @source.url).with(headers: { "If-None-Match" => '"v1"' }).to_return(status: 304)

    assert_equal 0, SourceRefresher.call(@source)

    @source.reload
    assert_equal '"v1"', @source.etag
    assert_equal 90.minutes.to_i, @source.fetch_interval
    assert_equal "not_modified", @source.fetch_logs.last.status
  end

  test "backs off on errors and stops after too many" do
    stub_request(:get, @source.url).to_return(status: 500)

    SourceRefresher.call(@source)
    @source.reload
    assert_equal 1, @source.error_count
    assert_match "HTTP 500", @source.last_error
    assert @source.active?
    assert_in_delta 2.hours.from_now, @source.next_fetch_at, 5.seconds
    assert_equal "failed", @source.fetch_logs.last.status

    @source.update!(error_count: Source::MAX_ERRORS - 1)
    SourceRefresher.call(@source)
    assert @source.reload.error?
  end

  test "a successful fetch clears previous errors" do
    @source.update!(error_count: 3, last_error: "boom", status: :error)
    stub_get @source.url, fixture: "feeds/rss.xml"

    SourceRefresher.call(@source)

    @source.reload
    assert @source.active?
    assert_equal 0, @source.error_count
    assert_nil @source.last_error
  end

  test "pauses feeds that are gone" do
    stub_request(:get, @source.url).to_return(status: 410)

    SourceRefresher.call(@source)

    assert @source.reload.paused?
  end

  test "follows permanent redirects to the new feed URL" do
    stub_request(:get, @source.url).to_return(status: 301, headers: { "Location" => "https://example.com/new-feed.xml" })
    stub_get "https://example.com/new-feed.xml", fixture: "feeds/rss.xml"

    SourceRefresher.call(@source)

    assert_equal "https://example.com/new-feed.xml", @source.reload.url
  end
end
