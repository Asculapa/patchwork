class AddDigestNotificationColumnsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :last_morning_notification_on, :date
    add_column :users, :last_evening_notification_on, :date
  end
end
