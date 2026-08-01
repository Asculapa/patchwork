require "test_helper"

class ScheduleDueSourcesJobTest < ActiveJob::TestCase
  test "enqueues due sources that have subscribers and leases them" do
    assert_enqueued_with(job: FetchSourceJob, args: [ sources(:blog) ]) do
      ScheduleDueSourcesJob.perform_now
    end

    assert_enqueued_jobs 1, only: FetchSourceJob # youtube isn't due, orphan has no subscribers
    assert_operator sources(:blog).reload.next_fetch_at, :>, 10.minutes.from_now
  end

  test "skips paused and failed sources" do
    sources(:blog).update!(status: :paused)
    ScheduleDueSourcesJob.perform_now
    assert_no_enqueued_jobs only: FetchSourceJob
  end
end
