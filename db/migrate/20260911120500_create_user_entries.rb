class CreateUserEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :user_entries do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :entry, null: false, foreign_key: { on_delete: :cascade }
      t.references :subscription, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.datetime :published_at, null: false
      t.datetime :read_at
      t.datetime :starred_at
      t.timestamps
    end
    add_index :user_entries, %i[user_id entry_id], unique: true
    add_index :user_entries, %i[user_id read_at published_at]
    add_index :user_entries, %i[user_id starred_at]
    add_index :user_entries, %i[subscription_id read_at]
  end
end
