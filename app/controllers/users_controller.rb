class UsersController < ApplicationController

  before_filter :login_required, :except => [:fix_profile_image_url]
  before_filter :registration_required, :except => [:setup, :fix_profile_image_url]
  before_filter :location_required, :except => [:setup, :set_location, :get_locations, :fix_profile_image_url]
  before_filter :set_recently_online_users, :except => [:setup, :fix_profile_image_url]
  before_filter :track_profile_view, :only => [:show]
  
  def show
    @user = User.find_by_login(params[:id])

    if @user.present?
      old_login = @user.login
      @user.update_login_from_twitter!
      if @user.login != old_login
        redirect_to(user_url(@user)) && return
      end

      @latest_tweets = get_latest_tweets(@user)
      store_viewed_user_in_session(@user)
      return
    end

    if logged_in?
      twitter_user_hash = current_user.get_user_from_twitter_as_hash(params[:id])
    else
      twitter_user_hash = User.find_by_twitter_id(Constants::POT_BOT_ID).get_user_from_twitter_as_hash(params[:id])
    end
    if twitter_user_hash.present?
      @user = User.new_from_twitter_auth_user_hash(twitter_user_hash)
    end
    
    @latest_tweets = get_latest_tweets(@user)
    store_viewed_user_in_session(@user)
  end
  
  def fix_profile_image_url
    return unless request.post?

    username_with_broken_image = params[:username_with_broken_image]

    # Properly expiring every fragment affected by a user's profile image
    # url changing requires expiring almost the whole app cache. To keep
    # it simple, we'll just expire the most obvious stale key.
    Rails.cache.delete("/users/show/#{username_with_broken_image}")

    correct_image_url = ""
    pot_bot = User.get_pot_bot

    updated_user = pot_bot.twitter.get("/users/show/#{username_with_broken_image}")
    if updated_user.present?
      correct_image_url = updated_user["profile_image_url"]

      if username_with_broken_image.present?
        user_needing_fixing = User.find_by_login(username_with_broken_image)
        if user_needing_fixing.present?
          user_needing_fixing.profile_image_url = correct_image_url
          user_needing_fixing.save!
        end
      end
    end
    
    image_id = params[:image_id]
    if image_id.present?
      render :js => "user_img = document.getElementById('#{image_id}'); user_img.src = '#{correct_image_url}'; user_img.onerror = '';"
    else
      render :nothing => true
    end
  end
  
  def random_profile
    if logged_in?
      @user = User.find(:first,
                        :conditions => ["gender = ? AND interested_in = ? and joined_on IS NOT NULL",
                                        current_user.interested_in, current_user.gender],
                        :order => "RAND()")
    else
      @user = User.find(:first, :conditions => "joined_on IS NOT NULL", :order => "RAND()")
    end
    @latest_tweets = get_latest_tweets(@user)
    render :action => :show
  end

  def manage_photos
    if request.put? && params[:user].present? && params[:user][:photo_attributes].present?
      current_user.photo_attributes = params[:user][:photo_attributes]
      if current_user.valid?
        current_user.save!
        redirect_to manage_photos_users_url
      end
      return
    elsif request.delete?
      if params[:id].present?
        photo_to_delete = current_user.photos.find_by_id(params[:id])
        photo_to_delete.destroy if photo_to_delete.present?
      end
      redirect_to manage_photos_users_url
    end    
  end

  
  def setup
    if current_user.registered?
      redirect_to root_url
      return
    end
    
    if request.get?
      set_user_defaults
      render :layout => false
    elsif request.post?
      begin
        current_user.register_and_send_welcome_message! params[:user].merge(:from_controller => self)
        current_user.notify_interested!
        redirect_to set_location_users_url
      rescue ActiveRecord::RecordInvalid
        render :layout => false
      end
    end
  end
  
  def set_location
    if params[:location].present?
      current_user.attributes = params[:location]
      current_user.save!
      expire_fragment "users-nearby-#{current_user.login}"
      render :update do |page|
        page.replace "current-location", :partial => "current_location"
        page.visual_effect :highlight, "current-location", :duration => 10
        page.visual_effect :fold, "matching-locations"
        page['user_location'].value = ""
      end
    end
  end
  
  def email_settings
    return unless request.post?
    
    current_user.email_on_new_message = params[:user][:email_on_new_message]
    current_user.email_matches_notification = params[:user][:email_matches_notification]
    current_user.save!
    flash.now[:notice] = "Email settings updated."
  end
  
  def who_i_like
  end
  
  def who_likes_me
  end
  
  def get_locations
    ip_address = request.remote_addr
    matching_locations = GeoSearch.find_nearby_locations(:search_text => params[:user][:location], :ip_address => ip_address)
    render :update do |page|
      page.replace_html "matching-locations",
                        :partial => "matching_locations",
                        :locals => {:matching_locations => matching_locations,
                                    :search_text => params[:user][:location]}
      page.visual_effect :fold_out, "matching-locations", :duration => 1
    end
  end
  
  def follow
    current_user.follow(params[:id])
    render :update do |page|
      page.visual_effect :fade, "follow-button-container", :duration => 0.3
      page.delay 0.3 do
        page.replace_html "follow-button-container",
                          :partial => "unfollow_button",
                          :locals => {:login => params[:id]} 
        page.visual_effect :appear, "follow-button-container", :queue => "end", :duration => 0.3
      end
    end
  end
  
  def unfollow
    current_user.unfollow(params[:id])
    render :update do |page|
      page.visual_effect :fade, "follow-button-container", :duration => 0.3
      page.delay 0.3 do
        page.replace_html "follow-button-container",
                          :partial => "follow_button",
                          :locals => {:login => params[:id]} 
        page.visual_effect :appear, "follow-button-container", :queue => "end", :duration => 0.3
      end
    end
  end

  def like
    current_user.like_and_notify(params[:id])    
    render :nothing => true
  end
  
  def send_smile
    current_user.send_smile_and_notify(params[:id])
    render :nothing => true
  end

  def profile
    if request.put?
      current_user.attributes = params[:user]
      if current_user.valid?
        current_user.save!
        flash.now[:notice] = "Your profile has been updated."
      end
    end
  end
  
  def forward_to_paypal
    ##Create Transaction and Forward to Paypal.
    t = PaypalTransaction.new :user_id => current_user.id
    t.save!
    item_number = params["membership_type"]["id"]
    if item_number == 1
      amount = "9.95"
      item_name = "1 Week Subscription"
    else
      amount = "24.95"
      item_name = "1 Month Subscription"
    end
    
    values = {
      :business => ENV['PAYPAL_EMAIL_ADDRESS'],
      :cmd => '_xclick',
      :upload => 1,
      :return => root_url,
      :notify_url => 'http://174.6.206.221:53647' + payment_notifications_path,
      :amount => amount,
      :invoice => t.id,
      :item_name => item_name,
      :item_number => item_number
    }
    redirect_to ENV['PAYPAL_WEBSITE'] + "/cgi-bin/webscr?" + values.to_query
  end
  
  def screen_name_autocomplete_source
    respond_to do |format|
      format.json do
        render :json => current_user.screen_name_autocomplete_source.to_json
      end
    end
  end
  
  def upgrade_account
  end

  protected
  
  def store_viewed_user_in_session(viewed_user)
    return if viewed_user == current_user

    recently_viewed_users = session[:recently_viewed_users] || []

    unless recently_viewed_users.present? && recently_viewed_users.any? { |u| u[:login] == viewed_user.login }
      recently_viewed_users.unshift :login => viewed_user.login,
                                    :profile_image_url => viewed_user.profile_image_url,
                                    :age => viewed_user.age,
                                    :gender => viewed_user.gender, 
                                    :location => viewed_user.city_name.present? ? viewed_user.city_name : viewed_user.location
      if recently_viewed_users.size > 5
        recently_viewed_users = recently_viewed_users[0, 5]
      end
      session[:recently_viewed_users] = recently_viewed_users
    end
  end
    
  def set_user_defaults
    current_user.gender = "M" if current_user.gender.blank?
    current_user.interested_in = "F" if current_user.interested_in.blank?
    current_user.min_age = 20
    current_user.max_age = 35
  end
  
  def get_latest_tweets(user)
    latest_tweets_path = "/statuses/user_timeline/#{user.twitter_id}.json?count=15"
    begin
      # A hack needed to make the computed result stored in latest_tweets accessible
      # after the benchmark block is run.
      latest_tweets = nil

      self.class.benchmark "getting latest tweets for: #{user.login}", Logger::DEBUG, false do
        if logged_in?        
          latest_tweets = current_user.twitter.get(latest_tweets_path)
        else
          latest_tweets = User.get_pot_bot.twitter.get(latest_tweets_path)
        end
      end

      return latest_tweets
    rescue TwitterAuth::Dispatcher::Unauthorized
      # User likely has protected their tweets.
      return []
    end
  end
  
  def track_profile_view
    @user = User.find_by_login(params[:id])
    
    return unless @user.try(:registered?) && @user != current_user
    
    @user.profile_viewed_by_users << current_user
  end
    
  def viewing_random_profile?
    request.path =~ /random_profile/
  end
  helper_method :viewing_random_profile?
  
end
