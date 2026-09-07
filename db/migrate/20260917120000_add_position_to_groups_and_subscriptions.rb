class AddPositionToGroupsAndSubscriptions < ActiveRecord::Migration[8.1]
  def change
    # Null until the user arranges the sidebar by hand; unpositioned rows sort
    # after positioned ones, alphabetically.
    add_column :groups, :position, :integer
    add_column :subscriptions, :position, :integer
  end
end
