class Action < ActiveRecord::Base

  default_scope :order => "created_at DESC"
  belongs_to :item, :polymorphic => true
  validates_presence_of :item_id, :item_type
  
  def user_signup?
    item.kind_of? User
  end
  
  def user_like?
    item.kind_of? UserLike
  end
  
  def photo_upload?
    item.kind_of? Photo
  end
  
  def item=
    raise ActiveRecord::ActiveRecordError, "This cannot be set directly for now, due to an annoying AR bug."
  end
    
  def self.paginate_recent(page_opts = {})
    page_opts[:page] ||= 1

    paginate :page => page_opts[:page], :conditions => "item_type IN ('User', 'Photo')", :order => "created_at DESC", :per_page => 15
  end

end