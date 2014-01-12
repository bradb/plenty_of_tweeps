class ProfileView < ActiveRecord::Base
  belongs_to :viewed_by_user, :class_name => "User"
  belongs_to :seen_user, :class_name => "User"
end
