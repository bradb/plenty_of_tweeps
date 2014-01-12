class UserLike < ActiveRecord::Base
  default_scope :order => "created_at DESC"

  validates_uniqueness_of :target_user_id, :scope => :source_user_id, :on => :create, :message => "must be unique"
  validates_creation_count :maximum => 1, :scope => :source_user_id, :time_frame => 1.day,
                           :message => "liked profile limit exceeded (maximum 1 every 24 hours)", 
                           :if => :user_has_introvert_account?
  validates_creation_count :maximum => 5, :scope => :source_user_id, :time_frame => 1.day,
                           :message => "liked profile limit exceeded (maximum 5 every 24 hours)", 
                           :if => :user_has_connector_account?
  validates_creation_count :maximum => 12, :scope => :source_user_id, :time_frame => 1.day,
                           :message => "liked profile limit exceeded (maximum 12 every 24 hours)", 
                           :if => :user_has_social_skydiver_account?
  
  belongs_to :source_user, :class_name => "User"
  belongs_to :target_user, :class_name => "User"
  
  has_one :action, :as => :item, :dependent => :destroy
  
  after_create :log_like_action

  def log_like_action
    a = Action.new
    a.item_id = self.id
    a.item_type = self.class.name
    a.save!
  end
  
  def user_has_introvert_account?
    source_user.introvert?
  end
  
  def user_has_connector_account?
    source_user.connector?
  end
  
  def user_has_social_skydiver_account?
    source_user.social_skydiver?
  end

end
