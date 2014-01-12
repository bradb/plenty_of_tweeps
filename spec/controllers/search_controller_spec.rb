require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SearchController do

  integrate_views

  before(:each) do
    @user = Factory(:registered_guy, :friends_count => 50, :followers_count => 230)
    @f_24yo = Factory(:registered_girl, :birth_date => 24.years.ago)
    @f_28yo = Factory(:registered_girl, :birth_date => 28.years.ago)
    
    controller.stub!(:current_user).and_return(@user)
    Rails.cache.delete("recently_online_users")
  end
  
  it "should set recently online users with a GET to :all_twitter_users_nearby" do
    reged_girl = Factory(:registered_girl)
    
    @controller.stub!(:current_user).and_return(reged_girl)
    get :all_twitter_users_nearby
    
    assigns[:recently_online_users].should == [reged_girl]
  end

  it "should return a list of matching users for the given search params, when present" do
    get :nearby, :user => {:min_age => 25, :max_age => 35}    
    assigns[:matching_users_paginated].current_page_results.should == [@f_28yo]
    response.should render_template "search/nearby"
    response.should be_success
    response.should include_text(@f_28yo.login)
  end
  
  it "should return a list of matching users between the current_user's min_age and max_age, when no query params are present" do
    get :nearby

    assigns[:matching_users_paginated].current_page_results.should == [@f_24yo, @f_28yo]
    assigns[:search_user].min_age.should == @user.min_age
    assigns[:search_user].max_age.should == @user.max_age
    response.should render_template "search/nearby"
    response.should be_success
    response.should include_text(@f_24yo.login)
    response.should include_text(@f_28yo.login)
  end
  
  it "should render a list of registered friends with a GET to :friends" do
    @user.stub!(:get_twitter_friend_ids).and_return(nil)
    get :friends
    response.should render_template "search/friends"
    response.should be_success
    assigns[:matching_users_paginated].should_not be_blank
  end
  
  it "should render a list of registered followers with a GET to :followers" do
    @user.stub!(:get_twitter_follower_ids).and_return(nil)
    get :followers
    response.should render_template "search/followers"
    response.should be_success
    assigns[:matching_users_paginated].should_not be_blank
  end
  
  it "should render a list of all Twitter friends with a GET to :all_twitter_friends" do
    @user.stub!(:get_twitter_friends).and_return(nil)
    get :all_twitter_friends
    response.should render_template "search/all_twitter_friends"
    response.should be_success
    assigns[:matching_users_paginated].should_not be_blank
  end
  
  it "should render a list of all Twitter followers with a GET to :all_twitter_followers" do
    @user.stub!(:get_twitter_followers).and_return(nil)
    get :all_twitter_followers
    response.should render_template "search/all_twitter_followers"
    response.should be_success
    assigns[:matching_users_paginated].should_not be_blank
  end
  
  it "should render a list of all nearby Twitter users with a GET to :all_twitter_users_nearby" do
    placeholder_user = Factory(:registered_guy)
    User.stub!(:find_by_twitter_id).and_return(placeholder_user)
    location = Geokit::GeoLoc.new :country_code => "CA", :state => "AB",
                                  :city=> "Mackenzie No. 23", :lat=> 59.166031,
                                  :lng=> -118.739829,:zip=> nil
    GeoSearch.stub!(:geocode_search).and_return(location)
    get :all_twitter_users_nearby
    response.should render_template "search/all_twitter_users_nearby"
    response.should be_success
    assigns[:matching_users_paginated].should_not be_blank    
  end
  
  it "should redirect to all_twitter_users_nearby on a GET to :go_to_user" do
    get :go_to_user
    response.should redirect_to search_all_twitter_users_nearby_url
  end
  
  it "should render a page to browse major cities" do
    get :cities
    response.should be_success
    response.should render_template "search/cities"
  end
  
  context "GET to :image_gallery" do
    
    before(:each) do
      @introvert_guy = Factory(:introvert_guy)
      @connector_guy = Factory(:connector_guy)
      @social_skydiver_guy = Factory(:social_skydiver_guy)
    end
    
    it "should redirect Introvert accounts to search_all_twitter_users_nearby_url, and set flash[:payment_required]" do
      controller.stub(:current_user).and_return(@introvert_guy)
      get :image_gallery
      response.should redirect_to search_all_twitter_users_nearby_url
      flash[:payment_required].should == "Sorry, the image gallery is only available to paid members."
    end
    
    it "should render the image_gallery template for Connector accounts" do
      controller.stub(:current_user).and_return(@connector_guy)
      get :image_gallery
      response.should be_success
    end
    
    it "should render the image_gallery template for Social Skydiver accounts" do
      controller.stub(:current_user).and_return(@social_skydiver_guy)
      get :image_gallery
      response.should be_success
    end
    
  end

end
