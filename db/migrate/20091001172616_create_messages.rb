class CreateMessages < ActiveRecord::Migration

  def self.up
    create_table :messages do |t|
      t.integer :from_user_id
      t.integer :to_user_id
      t.string :subject
      t.string :body
      t.boolean :unread, :default => true
      t.boolean :deleted, :default => false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :messages
  end

end
