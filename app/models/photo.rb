class Photo < ActiveRecord::Base
  default_scope :order => "created_at DESC"

  belongs_to :user
  has_attached_file :data,  
    :styles => { :small => "100x100#", :thumb => '250x250>', :large => '640x480>' },  
    :default_style => :thumb,  
    :url => "/images/:class/:user_id/:id_:style_:basename.:extension",  
    :path => ":rails_root/public/images/:class/:user_id/:id_:style_:basename.:extension"  
  
  validates_presence_of :user_id, :on => :create, :message => "can't be blank"
  validates_attachment_presence :data
  validates_attachment_content_type :data, :content_type => ['image/jpeg', 'image/jpg', 'image/png', 'image/pjpeg']
  validates_attachment_size :data, :less_than => 5.megabytes
  validates_creation_count :maximum => 2, :message => "photo upload limit exceeded (maximum 2 allowed)",
                           :scope => :user_id, :if => :user_has_introvert_account?
  validates_creation_count :maximum => 4, :message => "photo upload limit exceeded (maximum 4 allowed)",
                           :scope => :user_id, :if => :user_has_connector_account?
  validates_creation_count :maximum => 10, :message => "photo upload limit exceeded (maximum 10 allowed)",
                           :scope => :user_id, :if => :user_has_social_skydiver_account?
  
  
  after_create :log_photo_upload
  has_one :action, :as => :item, :dependent => :destroy
  
  def log_photo_upload
    a = Action.new
    a.item_id = self.id
    a.item_type = self.class.name
    a.save!
  end
  
  def self.recently_uploaded(user)
    find(:all,
         :conditions => ["users.birth_date >= ? && users.birth_date <= ? && users.gender = ? && users.interested_in = ?",
                         earliest_birth_date(user.max_age), latest_birth_date(user.min_age), user.interested_in,
                         user.gender],
         :joins => :user, :order => "RAND()", :limit => 20)
  end
  
  def user_has_introvert_account?
    user.try(:introvert?)
  end
  
  def user_has_connector_account?
    user.try(:connector?)
  end
  
  def user_has_social_skydiver_account?
    user.try(:social_skydiver?)
  end

end
