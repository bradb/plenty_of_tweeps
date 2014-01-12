module SearchHelper
  
  def subnav_tab_links
    [
      { :url_path => search_nearby_path, :text => "Members Nearby", :selected => (request.path == search_nearby_path) },
      { :url_path => search_all_twitter_users_nearby_path, :text => "All Twitter Users Nearby", :selected => (request.path == search_all_twitter_users_nearby_path || request.path.index('cities/').present?) },
    ]
  end
  
  def normalize_city_name_for_url(city_name)
    return unless city_name.present?
    
    city_name.strip.gsub(/\s+/, "-").gsub(/[^a-z1-9\-]/i, "").downcase
  end

end
