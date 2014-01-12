class LengthenUsersExtendedBio < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE users MODIFY extended_bio text"
  end

  def self.down
    execute "ALTER TABLE users MODIFY extended_bio varchar(255);"
  end
end
