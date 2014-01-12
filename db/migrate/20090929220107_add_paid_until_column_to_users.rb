class AddPaidUntilColumnToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :paid_until, :datetime
  end

  def self.down
    remove_column :users, :paid_until
  end
end
