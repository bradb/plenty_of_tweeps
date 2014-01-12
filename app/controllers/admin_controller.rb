class AdminController < ApplicationController

  before_filter :login_required
  before_filter :registration_required, :location_required
  before_filter :admin_required

  def import_nearby
    @matching_users_paginated = current_user.paginate_import_nearby_twitter_users(:page => params[:page],:twitter_username => params[:twitter_username])
  end

  def ignore
    render :update do | page |
      page.hide "user-#{params[:index_on_page]}"
    end  
  end

  def set_gender
    unless User.exists?(:login => params[:login])
      twitter_user_hash = current_user.get_user_from_twitter_as_hash(params[:login])
      if twitter_user_hash.present?
        @user = User.new_from_twitter_auth_user_hash(twitter_user_hash)
        @user.gender = params[:gender]
        @user.lat = current_user.lat
        @user.lng = current_user.lng
        @user.city_name = current_user.city_name
        @user.prov_state_code = current_user.prov_state_code
        @user.country_code = current_user.country_code
        if @user.gender == "M"
          @user.interested_in = "F"
        else
          @user.interested_in = "M"
        end
        @user.save!
      end
    end
    render :update do | page |
      page.hide "user-#{params[:index_on_page]}"
    end
  end

  private

  def admin_required
    unless ['72346755', '6453492', '14174460'].include?(current_user.twitter_id)
      redirect_to root_url
    end
  end  
  
end
