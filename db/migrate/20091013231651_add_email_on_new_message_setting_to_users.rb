class AddEmailOnNewMessageSettingToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :email_on_new_message, :boolean, :default => true
  end

  def self.down
    remove_column :users, :email_on_new_message
  end
end
