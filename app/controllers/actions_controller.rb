class ActionsController < ApplicationController
  before_filter :login_required, :registration_required, :location_required_if_logged_in, :set_recently_online_users, :except => :likes
  before_filter :set_recently_viewed_users, :only => [:index]

  def index

  end
  
  def likes
    if logged_in?
      redirect_to who_likes_me_all_users_url
    else
      redirect_to root_url
      # 2009-11-23, Brad Bollenbach: I'm commenting this out for now, since
      # this workflow appear to make no difference in the conversion rate.
      #
      # @liked_user = User.find_by_login(params[:user])
      # unless @liked_user.present?
      #   redirect_to root_url
      #   return
      # end
      # 
      # @users_that_might_like = User.find_users_that_might_like(@liked_user)
      # unless @users_that_might_like.present?
      #   redirect_to root_url
      #   return
      # end
      # 
      # render :layout => false
    end
  end

  protected
  
  def location_required_if_logged_in
    location_required if logged_in?
  end
  
end