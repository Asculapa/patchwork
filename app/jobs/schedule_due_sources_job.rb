# Runs every minute (config/recurring.yml) and enqueues a fetch for each
# source whose next_fetch_at has passed.
class ScheduleDueSourcesJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 500

  def perform
    Source.due.order(:next_fetch_at).limit(BATCH_SIZE).each do |source|
      # Lease the source so the next run doesn't enqueue it again while this fetch is waiting.
      source.update_column(:next_fetch_at, Source::FETCH_LEASE.from_now)
      FetchSourceJob.perform_later(source)
    end
  end
end
