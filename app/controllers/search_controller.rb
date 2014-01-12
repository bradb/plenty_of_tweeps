class SearchController < ApplicationController

  before_filter :login_required, :registration_required, :location_required
  before_filter :paid_account_required, :only => [:image_gallery]
  before_filter :set_recently_online_users
  before_filter :set_recently_viewed_users, :only => [:nearby, :all_twitter_users_nearby]

  helper_method :get_nearby_search_params

  def nearby
    ns_params = get_nearby_search_params
    @search_user = User.new ns_params
    @matching_users_paginated = current_user.paginate_find_nearby(ns_params.merge(:page => params[:page]))
  end
  
  def cities
    
  end

  def friends
    @matching_users_paginated = current_user.paginate_only_reged_friends :page => params[:page] 
  end
  
  def followers
    @matching_users_paginated = current_user.paginate_only_reged_followers :page => params[:page] 
  end
  
  def all_twitter_friends
    @matching_users_paginated = current_user.paginate_all_friends :page => params[:page]
  end
  
  def all_twitter_followers
    @matching_users_paginated = current_user.paginate_all_followers :page => params[:page]
  end
  
  def go_to_user
    redirect_to search_all_twitter_users_nearby_url
  end

  def all_twitter_users_nearby
    if logged_in? && params[:city].blank? && params[:country_code].blank?
      lat = current_user.lat
      lng = current_user.lng
      @city_name = current_user.city_name
    else
      if RAILS_ENV == "development"
        ip_address = "174.6.206.221"
      else
        ip_address = request.remote_addr
      end
      if params[:city].present? && params[:country_code].present?
        location_from_ip = GeoSearch.geocode_search(:search_text => params[:city] + ", " + Constants::COUNTRIES[params[:country_code].upcase])
      else
        location_from_ip = GeoSearch.geocode_search(:search_text => ip_address)
      end
      lat = location_from_ip.lat
      lng = location_from_ip.lng
      @city_name = location_from_ip.city
      if params[:city].present?
        if /louisville/ =~ params[:city].downcase
          @city_name = "Louisville"
        end
      end
    end
    @matching_users_paginated = (logged_in? ? current_user : User.find_by_twitter_id(Constants::POT_BOT_ID)).paginate_all_twitter_users_nearby(
      :page => params[:page], :lat => lat,:lng => lng)
  end

  def ignore
    render :update do | page |
      page.hide "user-#{params[:index_on_page]}"
    end  
  end

  
  protected
  
  def get_nearby_search_params
    ns_params = {}
    [:gender, :interested_in, :min_age, :max_age].each do |search_param|
      if params[:user].present? && params[:user][search_param].present?
        ns_params[search_param] = params[:user][search_param]
      else
        ns_params[search_param] = current_user.send(search_param)
      end
    end

    return ns_params
  end
  
  def paid_account_required
    unless (current_user.connector? || current_user.social_skydiver?) && current_user.is_paid_up?
      flash[:payment_required] = "Sorry, the image gallery is only available to paid members."
      redirect_to search_all_twitter_users_nearby_url
    end
  end

end
