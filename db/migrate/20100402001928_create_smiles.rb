class CreateSmiles < ActiveRecord::Migration
  def self.up
    create_table :smiles do |t|
      t.integer :source_user_id
      t.integer :target_user_id
      t.boolean :deleted, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :smiles
  end
end
