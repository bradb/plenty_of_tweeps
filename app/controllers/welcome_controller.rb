class WelcomeController < ApplicationController
  
  before_filter :login_required, :registration_required, :set_recently_online_users, :only => [:thanks, :payment_cancelled]
  
  layout "application"

  def index
    if logged_in?
      redirect_to recent_activity_url
    else
      render :layout => false
    end
  end

  def about
    
  end
  
  def contact_us
    
  end
  
  def faq
    
  end
  
  def terms
    
  end
  
  def privacy
    
  end
  
  def cities
  
  end
  
  def thanks
    
  end
  
  def payment_cancelled
    
  end

end
