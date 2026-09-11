module Ingest
  # Stores normalised entries for a source and fans the new ones out to every
  # subscriber. Idempotent: re-ingesting the same entries only updates edits.
  class Entries
    UPDATABLE = %i[url title author summary content_html image_url media fingerprint].freeze
    BATCH_SIZE = 1_000

    def self.call(source, entries)
      new(source, entries).call
    end

    def initialize(source, entries)
      @source = source
      @entries = entries.uniq(&:guid)
    end

    # Returns the number of entries that were new for this source.
    def call
      return 0 if @entries.empty?

      Entry.transaction do
        existing_guids = @source.entries.where(guid: guids).pluck(:guid)
        Entry.upsert_all(rows, unique_by: %i[source_id guid], update_only: UPDATABLE)

        new_entries = @source.entries.where(guid: guids - existing_guids).pluck(:id, :published_at)
        fan_out(new_entries)
        new_entries.size
      end
    end

    private
      def guids
        @entries.map(&:guid)
      end

      def rows
        @entries.map { |entry| entry.to_h.merge(source_id: @source.id) }
      end

      def fan_out(new_entries)
        return if new_entries.empty?

        subscriptions = @source.subscriptions.pluck(:id, :user_id)
        rows = subscriptions.product(new_entries).map do |(subscription_id, user_id), (entry_id, published_at)|
          { user_id: user_id, entry_id: entry_id, subscription_id: subscription_id, published_at: published_at }
        end
        rows.each_slice(BATCH_SIZE) { |batch| UserEntry.insert_all(batch, unique_by: %i[user_id entry_id]) }
      end
  end
end
