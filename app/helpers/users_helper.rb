module UsersHelper

  def profile_subnav_tab_links
    [
      {:url_path => profile_users_path, :text => "Edit Profile" },
      {:url_path => set_location_users_path, :text => "Change Location" },
      {:url_path => manage_photos_users_path, :text => "Manage Photos" },
      {:url_path => email_settings_users_path, :text => "Email Settings" },
      {:url_path => upgrade_account_users_path, :text => "Upgrade Account"}
    ]
  end

  def who_likes_me_subnav_tab_links
    [
      {:url_path => who_likes_me_all_users_path, :text => "Show All (#{current_user.liked_by_users.count})" }
    ]
  end
  
  def profile_upgrade_account_box_text(user)
    limits_reached = []
    
    limits_reached << "sending smiles" if user.daily_smile_limit_reached?
    limits_reached << "sending messages" if user.daily_message_limit_reached?
    limits_reached << "liking profiles" if user.daily_like_profile_limit_reached?

    return limits_reached.present? ? limits_reached.to_sentence : nil
  end
  
  def show_checkmark_if(condition)
    return condition ? image_tag("checkmark_icon_16.png") : "&mdash;"
  end

end
