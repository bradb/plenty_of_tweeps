class Smile < ActiveRecord::Base
  belongs_to :source_user, :class_name => "User", :foreign_key => "source_user_id"
  belongs_to :target_user, :class_name => "User", :foreign_key => "target_user_id"
  
  default_scope :conditions => { :deleted => false }
  
  validates_creation_count :maximum => 1, :time_frame => 1.day,
                           :message => "smile sending limit exceeded (maximum 1 every 24 hours)",
                           :scope => :source_user_id, :if => :user_has_introvert_account?
  validates_creation_count :maximum => 5, :time_frame => 1.day,
                           :message => "smile sending limit exceeded (maximum 5 every 24 hours)",
                           :scope => :source_user_id, :if => :user_has_connector_account?
  validates_creation_count :maximum => 12, :time_frame => 1.day,
                           :message => "smile sending limit exceeded (maximum 12 every 24 hours)",
                           :scope => :source_user_id, :if => :user_has_social_skydiver_account?
                    
  
  def seen!
    soft_delete
  end
  
  protected
  
  def user_has_introvert_account?
    source_user.introvert?
  end
  
  def user_has_connector_account?
    source_user.connector?
  end
  
  def user_has_social_skydiver_account?
    source_user.social_skydiver?
  end
  
  def soft_delete
    self.deleted = true
    save!
  end

end
