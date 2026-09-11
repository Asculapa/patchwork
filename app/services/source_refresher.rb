# Fetches one source, stores its new entries, schedules the next fetch and
# records the attempt in fetch_logs.
class SourceRefresher
  def self.call(source)
    new(source).call
  end

  def initialize(source)
    @source = source
  end

  # Returns the number of new entries.
  def call
    started_at = Time.current
    result = @source.fetcher_class.new(@source).fetch
    new_count = result.not_modified ? 0 : Ingest::Entries.call(@source, result.entries)

    @source.record_success!(result, new_count)
    log started_at, status: result.not_modified ? :not_modified : :ok, http_status: result.http_status, new_entries_count: new_count
    new_count
  rescue Fetchers::Error => error
    @source.record_failure!(error.message, status: (:paused if error.is_a?(Fetchers::Gone)))
    log started_at, status: :failed, error: error.message
    0
  end

  private
    def log(started_at, **attributes)
      @source.fetch_logs.create!(duration_ms: ((Time.current - started_at) * 1000).round, **attributes)
    end
end
