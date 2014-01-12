require File.dirname(__FILE__) + '/../spec_helper'

describe WelcomeController do
  
  integrate_views

  context "GET to :thanks" do
    
    it "should respond successfully for logged in users" do
      reged_guy = Factory(:registered_guy)
      controller.stub(:current_user).and_return(reged_guy)
      get :thanks
      response.should be_success
    end
    
    it "should thank the user" do
      reged_guy = Factory(:registered_guy)
      controller.stub(:current_user).and_return(reged_guy)
      get :thanks
      response.body.should match /thank you/i
    end
    
    it "should redirect to the login_url for unauthenticated users" do
      get :thanks
      response.should redirect_to login_url
    end
    
  end
  
  context "GET to :payment_cancelled" do

    it "should respond successfully for logged in users" do
      reged_guy = Factory(:registered_guy)
      controller.stub(:current_user).and_return(reged_guy)
      get :payment_cancelled
      response.should be_success
    end
    
    it "should tell the user that their payment was cancelled" do
      reged_guy = Factory(:registered_guy)
      controller.stub(:current_user).and_return(reged_guy)
      get :payment_cancelled
      response.body.should match /payment cancelled/i
    end
    
    it "should redirect to the login_url for unauthenticated users" do
      get :payment_cancelled
      response.should redirect_to login_url
    end
    
  end
  
end