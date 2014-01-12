require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ActionsController do 
  integrate_views
  
  before :each do
    Rails.cache.delete("recently_online_users")
    @user = Factory(:registered_guy)
    controller.stub(:current_user).and_return(@user)
  end
  
  it "should set recently online users with an authenticated GET to :index, to a maximum of 10 users" do
    recently_online_users = []
    10.times do
      recently_online_users << Factory(:registered_girl)
    end
    recently_online_users.should have(10).things
    recently_online_users.each do | recently_online_user |
      controller.stub(:current_user).and_return(recently_online_user)
      get :index
    end
    assigns[:recently_online_users].should have(10).things
    assigns[:recently_online_users].should == recently_online_users.reverse
  end
  
  it "should FIFO out the first recently online user when an 11th user is added" do
    recently_online_users = []
    11.times do
      recently_online_users << Factory(:registered_girl)
    end
    recently_online_users.should have(11).things
    recently_online_users.each do | recently_online_user |
      controller.stub(:current_user).and_return(recently_online_user)
      get :index
    end
    assigns[:recently_online_users].should have(10).things
    assigns[:recently_online_users].should == recently_online_users.reverse[0, 10]
  end
  
  it "should not add duplicates to the recently online users" do
    reged_guy = Factory(:registered_guy)
    reged_girl = Factory(:registered_girl)
    
    controller.stub(:current_user).and_return(reged_guy)
    get :index
    assigns[:recently_online_users].should == [reged_guy]
    
    controller.stub(:current_user).and_return(reged_girl)
    get :index
    assigns[:recently_online_users].should == [reged_girl, reged_guy]

    controller.stub(:current_user).and_return(reged_guy)
    get :index
    assigns[:recently_online_users].should == [reged_girl, reged_guy]
  end
  
  it "should not add users without a city_name to recently online users" do
    reged_girl = Factory(:registered_girl)
    reged_girl.city_name = ""
    reged_girl.save!
    
    controller.stub(:current_user).and_return(reged_girl)
    get :index
    puts assigns[:recently_online_users]
  end
  
  it "should show users nearby with a GET to :index" do
    get :index
    response.should be_success
    response.body.should match(/Users Nearby/i)
  end

  it "should cache users nearby" do
    lambda { get :index }.should cache_fragment("views/users-nearby-#{@user.login}")
  end
  
  it "should cache photos uploaded" do
    lambda { get :index }.should cache_fragment("views/photo-uploads-#{@user.login}")
  end
  
  it "should redirect to the homepage with an unauthenticated GET to :likes" do
    controller.stub(:current_user).and_return(nil)
    get :likes
    response.should redirect_to root_url
  end
  
  it "should redirect a user to /users/who_likes_me_all with an auth'd GET to :likes" do
    reged_girl = Factory(:registered_girl)
    controller.stub(:current_user).and_return(reged_girl)
    
    get :likes, :user => reged_girl.login
    response.should redirect_to who_likes_me_all_users_url
  end
  
end

