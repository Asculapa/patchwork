class AddCollapsedToGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :groups, :collapsed, :boolean, default: false, null: false
  end
end
