class CreateUserEvaluations < ActiveRecord::Migration
  def self.up
    create_table :user_evaluations do |t|
      t.column :source_user_id, :integer
      t.column :target_user_id, :integer
      t.column :interested, :boolean

      t.timestamps
    end
  end

  def self.down
    drop_table :user_evaluations
  end
end
