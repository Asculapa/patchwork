class CreateFetchLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :fetch_logs do |t|
      t.references :source, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :status, null: false
      t.integer :http_status
      t.integer :new_entries_count, null: false, default: 0
      t.integer :duration_ms
      t.text :error
      t.datetime :created_at, null: false
    end
    add_index :fetch_logs, %i[source_id created_at]
  end
end
