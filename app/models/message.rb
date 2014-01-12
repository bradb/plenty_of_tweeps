class Message < ActiveRecord::Base
  default_scope :conditions => { :deleted => false }, :order => "created_at DESC"

  validates_creation_count :maximum => 1, :time_frame => 1.day, :scope => :from_user_id,
                           :message => "message sending limit exceeded (maximum 1 every 24 hours)",
                           :if => :user_has_introvert_account?
  validates_creation_count :maximum => 5, :time_frame => 1.day, :scope => :from_user_id,
                           :message => "message sending limit exceeded (maximum 5 every 24 hours)",
                           :if => :user_has_connector_account?
  validates_creation_count :maximum => 12, :time_frame => 1.day, :scope => :from_user_id,
                           :message => "message sending limit exceeded (maximum 12 every 24 hours)",
                           :if => :user_has_social_skydiver_account?
          
                    
  validates_presence_of :subject, :body, :from_user_id, :to_user_id
  belongs_to :to_user, :class_name => "User"
  belongs_to :from_user, :class_name => "User"
  validates_length_of :subject, :within => 2..50, :on => :create, :message => "must be 2 to 50 characters long"
  validates_length_of :body, :maximum => 2000, :on => :create, :message => "must be present"

  def mark_read!
    self.unread = false
    save!
  end
  
  def user_has_introvert_account?
    from_user.introvert?
  end
  
  def user_has_connector_account?
    from_user.connector?
  end
  
  def user_has_social_skydiver_account?
    from_user.social_skydiver?
  end

end
