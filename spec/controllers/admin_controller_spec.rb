require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminController do 
  integrate_views
  
  it "should not be able to access the import page from a registered user." do
    u = Factory.create(:registered_guy)
    @controller.stub!(:current_user).and_return(u)
    fake_authentication
    get :import_nearby
    response.should redirect_to root_url  
  end
    
  def fake_authentication
    controller.stub!(:login_required).and_return(true)
    controller.stub!(:registration_required).and_return(true)
  end

end

