class ChangeEntriesMediaToJsonb < ActiveRecord::Migration[8.1]
  def change
    # Postgres's json type has no equality operator, which breaks
    # Entry.upsert_all's change-detection WHERE clause; jsonb supports it.
    change_column :entries, :media, :jsonb, null: false, default: {}
  end
end
