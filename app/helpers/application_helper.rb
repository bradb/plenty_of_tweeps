# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def global_navigation_tabs
    tabs = [
      {:url_path => recent_activity_path,
       :text => "Activity",
       :id => "activity-tab",
       :selected => request.path == recent_activity_path},
      {:url_path => search_nearby_path,
       :text => "Search",
       :id => "search-tab",
       :selected => (@controller.controller_name == "search" ||
                    (@controller.controller_name == "users" && @controller.action_name == "show") ||
                    request.path == random_profile_users_path)},
      { :url_path => messages_path,
        :text => "Inbox (#{all_unread_messages_count})",
        :id => "inbox-tab",
        :selected => @controller.controller_name == "messages" },
      {:url_path => who_likes_me_all_users_path,
       :text => "Who Likes My Profile (#{who_likes_me_count})",
       :id => "who-likes-me-tab",
       :selected => ((request.path == who_likes_me_users_path) ||
                     (request.path == who_likes_me_all_users_path))},
      {:url_path => profile_users_url,
       :text => "Edit Profile",
       :id => "my-profile-tab",
       :selected => [profile_users_path, set_location_users_path,
                     manage_photos_users_path, email_settings_users_path].include?(request.path) }
    ]
  end
  
  def all_unread_messages_count
    current_user.present? ? current_user.all_unread_messages_count : 0
  end
  
  def who_likes_me_count
    if current_user.present?
      return current_user.who_likes_me_count
    else
      return 0
    end
  end
  
  def user_profile_image_tag(user)
    # Use SecureRandom to (basically) guarantee this image has a unique
    # id, since it's possible the same user image may be loaded multiple
    # times in one listing.
    image_id = "user-image-#{ActiveSupport::SecureRandom.hex(8)}"

    case user
    when User
      profile_image_url = user.profile_image_url
      login = user.login
    when Hash
      profile_image_url = user[:profile_image_url]
      login = user[:login]
    end

    image_tag(profile_image_url,
              :onerror => "jQuery.ajax({data:'username_with_broken_image=' + encodeURIComponent('#{login}') + '&image_id=' + encodeURIComponent('#{image_id}'), dataType:'script', type:'post', url:'/users/fix_profile_image_url'}); return false;",
              :id => image_id,
              :alt => login,
              :title => login, 
              :class => "user-image")
  end
  
  def auto_link_twitter_text(twitter_text)
    linkified_text = auto_link(twitter_text, :urls, :target => "_blank", :rel => "nofollow")
    return linkified_text.gsub(/\B(@(\w+))/, %Q{<a href="/users/\\2">\\1</a>})
  end
  
  def google_analytics_js
    '<script type="text/javascript">
    var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
    document.write(unescape("%3Cscript src=\'" + gaJsHost + "google-analytics.com/ga.js\' type=\'text/javascript\'%3E%3C/script%3E"));
    </script>
    <script type="text/javascript">
    try{
    var pageTracker = _gat._getTracker("UA-11110025-1");
    pageTracker._setDomainName(".plentyoftweeps.com");
    pageTracker._trackPageview();
    } catch(err) {}
    </script>'
  end
  
end
