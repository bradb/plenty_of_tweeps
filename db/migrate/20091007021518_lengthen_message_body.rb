class LengthenMessageBody < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE messages MODIFY body text"
  end

  def self.down
    execute "ALTER TABLE messages MODIFY body varchar(255);"
  end
end
