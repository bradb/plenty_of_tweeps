class AddPhotosToActions < ActiveRecord::Migration
  def self.up
    Photo.find(:all).each do |photo|
      a = Action.new
      a.item_id = photo.id
      a.item_type = photo.class.name
      a.created_at = photo.created_at
      a.save!
    end
  end

  def self.down
    Action.find(:all, :conditions => {:item_type => "Photo"}).each do |photo_action|
      photo_action.destroy
    end
  end
end
