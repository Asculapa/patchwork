class CreateSources < ActiveRecord::Migration[8.1]
  def change
    create_table :sources do |t|
      t.string :kind, null: false, default: "feed"
      t.string :visibility, null: false, default: "shared"
      t.references :owner, foreign_key: { to_table: :users, on_delete: :cascade }
      t.string :url, null: false
      t.string :site_url
      t.string :title
      t.text :description
      t.string :icon_url
      t.json :config, null: false, default: {}
      t.string :status, null: false, default: "active"
      t.string :etag
      t.string :last_modified
      t.datetime :last_fetched_at
      t.datetime :next_fetch_at
      t.integer :fetch_interval, null: false, default: 3600
      t.integer :error_count, null: false, default: 0
      t.text :last_error
      t.timestamps
    end
    add_index :sources, :url, unique: true, where: "visibility = 'shared'"
    add_index :sources, %i[status next_fetch_at]
  end
end
