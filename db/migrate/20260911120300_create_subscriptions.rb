class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :source, null: false, foreign_key: true
      t.references :group, foreign_key: { on_delete: :nullify }
      t.string :custom_title
      t.boolean :muted, null: false, default: false
      t.timestamps
    end
    add_index :subscriptions, %i[user_id source_id], unique: true
  end
end
