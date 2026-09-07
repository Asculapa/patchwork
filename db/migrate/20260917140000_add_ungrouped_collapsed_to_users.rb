class AddUngroupedCollapsedToUsers < ActiveRecord::Migration[8.1]
  def change
    # Whether the sidebar's "Other" section (sources with no group) is collapsed.
    add_column :users, :ungrouped_collapsed, :boolean, default: false, null: false
  end
end
