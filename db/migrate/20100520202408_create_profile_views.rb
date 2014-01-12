class CreateProfileViews < ActiveRecord::Migration
  def self.up
    create_table :profile_views do |t|
      t.references(:viewed_by_user)
      t.references(:seen_user)
      t.integer :deleted

      t.timestamps
    end
  end

  def self.down
    drop_table :profile_views
  end
end
