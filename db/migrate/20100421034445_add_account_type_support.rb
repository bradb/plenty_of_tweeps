class AddAccountTypeSupport < ActiveRecord::Migration
  def self.up
    add_column :users, :account_type, :string, :limit => 1, :default => "I"
    add_column :users, :months_remaining, :integer
  end

  def self.down
    remove_column :users, :months_remaining
    remove_column :users, :account_type
  end
end
