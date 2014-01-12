class AddExtendedBioToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :extended_bio, :string
  end

  def self.down
    remove_column :users, :extended_bio
  end
end
