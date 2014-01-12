class CreateActions < ActiveRecord::Migration
  def self.up
    create_table :actions do |t|
      t.references :item, :polymorphic => true
      t.timestamps
    end
    
    users = User.find(:all, :conditions => "joined_on IS NOT NULL")
    user_likes = UserLike.find(:all)
    sorted_items = (users + user_likes).sort { |x, y| x.created_at <=> y.created_at }
    sorted_items.each do |item|
      a = Action.new
      a.item_id = item.id
      a.item_type = item.class.name
      a.save!
    end
  end

  def self.down
    drop_table :actions
  end
end
