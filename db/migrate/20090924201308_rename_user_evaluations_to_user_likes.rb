class RenameUserEvaluationsToUserLikes < ActiveRecord::Migration
  def self.up
    rename_table :user_evaluations, :user_likes
    remove_column :user_likes, :interested
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
