class CreateEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :entries do |t|
      t.references :source, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :guid, null: false
      t.string :url
      t.string :title, null: false
      t.string :author
      t.text :summary
      t.text :content_html
      t.string :image_url
      t.json :media, null: false, default: {}
      t.datetime :published_at, null: false
      t.string :fingerprint
      t.timestamps
    end
    add_index :entries, %i[source_id guid], unique: true
    add_index :entries, %i[source_id published_at]
    add_index :entries, :fingerprint
  end
end
