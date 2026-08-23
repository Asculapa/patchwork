class AddConfirmedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :confirmed_at, :datetime

    # Existing accounts predate confirmation; don't lock them out.
    up_only { User.update_all(confirmed_at: Time.current) }
  end
end
