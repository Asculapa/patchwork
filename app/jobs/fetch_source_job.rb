class FetchSourceJob < ApplicationJob
  queue_as :fetch
  limits_concurrency to: 1, key: ->(source) { source }, duration: 5.minutes
  discard_on ActiveJob::DeserializationError

  def perform(source)
    SourceRefresher.call(source)
  end
end
