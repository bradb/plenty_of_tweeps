# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include ExceptionNotifiable

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password

  def set_recently_viewed_users
    @recently_viewed_users = session[:recently_viewed_users]
  end
  
  def set_recently_online_users
    if not logged_in?
      @recently_online_users = Rails.cache.fetch("recently_online_users")
      return
    end
    
    recently_online_users = Rails.cache.fetch("recently_online_users") do
      if current_user.city_name.present?
        [current_user]
      else
        []
      end
    end
    
    # The array returned by the Rails.cache is frozen, so we update it by reconstructing
    # it from scratch.
    @recently_online_users = []
    recently_online_users.each do | recently_online_user |
      @recently_online_users << recently_online_user
    end
    @recently_online_users.unshift(current_user) unless (@recently_online_users.include?(current_user) || current_user.city_name.blank?)
    
    if @recently_online_users.size > 10
      @recently_online_users = @recently_online_users[0, 10]
    end

    Rails.cache.write("recently_online_users", @recently_online_users)
  end

  def rescue_404
    rescue_action_in_public(ActionController::RoutingError)
  end

  def rescue_action_in_public(exception)
    if exception == ActionController::RoutingError || exception.is_a?(ActionController::UnknownAction)
      render :template => "errors/404", :status => "404"
    else
      render :template => "errors/500", :status => "500"
    end          
  end

  def local_request?
    return false
  end
  
  protected

  def local_request?
    if current_user.present?
      if current_user.twitter_id == Constants::POT_BOT_ID.to_s
        return true
      end
    else
      return false
    end
  end


  # Ensure that the current use has completed registration. If not,
  # redirect them to the registration page.
  def registration_required
    if current_user.joined_on.blank?
      # A user without an birth_date is a telltale sign of someone who hasn't yet
      # registered with PoT. So we'll collect the needed metadata from
      # them before returning them to original destination URL.
      store_location
      redirect_to setup_users_url
    end
  end

  def location_required
    unless current_user.present? && current_user.lat.present? && current_user.lng.present?
      redirect_to set_location_users_url
      return false
    end
  end
  
  # Override the twitter-auth defaults here, because we don't need
  # the flash notice for successful login that twitter-auth provides
  # by default.
  def authentication_succeeded(message = '', destination = '/')
    flash[:notice] = message
    redirect_back_or_default destination
  end

end
