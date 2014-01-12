require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UsersController do
  
  integrate_views

  before(:each) do
    @unreged_user = Factory(:unregistered_user)
    @f_24yo = Factory(:registered_girl, :birth_date => 24.years.ago)

    FakeWeb.register_uri(:get, %r{/friendships/exists}, :body => "false")
    controller.stub(:current_user).and_return(@unreged_user)
    controller.stub(:get_latest_tweets).and_return([])
    fake_pot_bot = Factory(:unregistered_user)
    User.stub(:get_pot_bot).and_return(fake_pot_bot)
    User.stub(:get_pot_human).and_return(fake_pot_bot)
    @valid_attributes = {"birth_date(1i)" => "1984", "birth_date(2i)" => "10", "birth_date(3i)" => "30"}.merge(Factory.attributes_for(:registered_guy))

    Rails.cache.delete("recently_online_users")
  end
  
  context "GET to :show" do
    
    before(:each) do
      @reged_guy = Factory(:registered_guy)
      @reged_girl = Factory(:registered_girl)
    end

    it "should set recently online users" do
      @reged_girl = Factory(:registered_girl)
      @controller.stub(:current_user).and_return(@reged_girl)

      get :show, :id => @reged_girl.login
      assigns[:recently_online_users].should == [@reged_girl]
    end

    it "should display a user" do
      @controller.stub(:current_user).and_return(Factory(:registered_guy))
      fake_authentication
      get :show, {:id => @unreged_user.login}
      response.should be_success
      response.should render_template "users/show"
      response.should include_text(@unreged_user.login)
    end
    
    it "should display an unregistered user" do
      @reged_guy = Factory(:registered_guy)
      @controller.stub(:current_user).and_return(@reged_guy)
      fake_authentication
      @reged_guy.stub(:get_user_from_twitter_as_hash).and_return(TWITTER_AUTH_USER_HASH)

      get :show, {:id => "ev"}
      response.should be_success
      response.should render_template "users/show"
      response.should include_text("ev")
    end
    
    it "should show a Follow on Twitter button on a user the current_user doesn't follow" do
      @reged_guy = Factory(:registered_guy)
      @reged_girl = Factory(:registered_girl)
      @controller.stub(:current_user).and_return(@reged_guy)
      FakeWeb.register_uri(:get, "https://twitter.com/friendships/exists.json?user_a=#{@reged_guy.login}&user_b=#{@reged_girl.login}", :body => "false")
      get :show, :id => @reged_girl.login
      response.should be_success
      response.should include_text("Follow on Twitter")
      response.should_not include_text("Unfollow on Twitter")
    end

    it "should show an Unfollow on Twitter button on a user the current_user follows" do
      @reged_guy = Factory(:registered_guy)
      @reged_girl = Factory(:registered_girl)
      @controller.stub(:current_user).and_return(@reged_guy)
      FakeWeb.register_uri(:get, "https://twitter.com/friendships/exists.json?user_a=#{@reged_guy.login}&user_b=#{@reged_girl.login}", :body => "true")
      get :show, :id => @reged_girl.login
      response.should be_success
      response.should include_text("Unfollow on Twitter")
      response.should_not include_text("Follow on Twitter")
    end
    
    it "should show the action buttons" do
      @reged_guy = Factory(:registered_guy)
      @reged_girl = Factory(:registered_girl)
      @controller.stub(:current_user).and_return(@reged_guy)
      get :show, :id => @reged_girl.login
      response.should be_success
      response.should have_tag("div.action-buttons")
    end
    
    it "should not show the action buttons when looking at one's own profile" do
      @reged_guy = Factory(:registered_guy)
      @controller.stub(:current_user).and_return(@reged_guy)
      get :show, :id => @reged_guy.login
      response.should be_success
      response.should_not have_tag("div.action-buttons")
    end
    
    it "should show the like button when the current user hasn't liked the user being viewed" do
      @reged_guy = Factory(:registered_guy)
      @reged_girl = Factory(:registered_girl)
      @controller.stub(:current_user).and_return(@reged_guy)
      get :show, :id => @reged_girl.login
      response.should be_success
      response.should have_tag("div.action-buttons a#like")
    end
    
    it "should not show the like button when the current user has already liked the user being viewed" do
      @reged_guy = Factory(:registered_guy)
      @reged_girl = Factory(:registered_girl)
      @controller.stub(:current_user).and_return(@reged_guy)
      @reged_guy.stub(:likes?).and_return(true)
      get :show, :id => @reged_girl.login
      response.should be_success
      response.should_not have_tag("div.action-buttons a#like")
    end
    
    it "should show the #you-like-this div when the current uesr has liked the user being viewed" do
      @reged_guy = Factory(:registered_guy)
      @reged_girl = Factory(:registered_girl)
      @controller.stub(:current_user).and_return(@reged_guy)
      @reged_guy.stub(:likes?).and_return(true)
      get :show, :id => @reged_girl.login
      response.should be_success
      response.should have_tag("div#you-like-this")      
    end
    
    it "should track the profile view for registered users" do
      ProfileView.count.should == 0
      @controller.stub(:current_user).and_return(@reged_guy)
      get :show, :id => @reged_girl.login
      response.should be_success
      ProfileView.count.should == 1
      ProfileView.first.viewed_by_user.should == @reged_guy
      ProfileView.first.seen_user.should == @reged_girl
    end
    
    it "should not track the profile view for users viewing themselves" do
      @controller.stub(:current_user).and_return(@reged_guy)
      proc do
        get :show, :id => @reged_guy.login
        response.should be_success
      end.should_not change(ProfileView, :count)
    end
    
    it "should not track the profile view for unregistered users that exist in the DB" do
      @controller.stub(:current_user).and_return(@reged_guy)
      proc do
        get :show, :id => @unreged_user.login
        response.should be_success
      end.should_not change(ProfileView, :count)
    end
    
    it "should not track the profile view for unregistered users that don't exist in the DB" do
      @controller.stub(:current_user).and_return(@reged_guy)
      @reged_guy.stub(:get_user_from_twitter_as_hash).and_return(TWITTER_AUTH_USER_HASH)
      
      proc do
        get :show, :id => "ev"
        response.should be_success
      end.should_not change(ProfileView, :count)      
    end
    
  end
  

  context "POST to :setup" do

    it "should allow proceeding without an email address" do
      post :setup, :user => @valid_attributes.except(:email)
      @unreged_user.should be_valid
      response.should redirect_to set_location_users_url
    end
  
    it "should not proceed without a gender" do
      post :setup, :user => @valid_attributes.except(:gender)
      @unreged_user.errors.should be_present
      @unreged_user.errors.on(:gender).should be_present
      response.should render_template "users/setup"
    end

    it "should not proceed without an interested_in" do
      post :setup, :user => @valid_attributes.except(:interested_in)
      @unreged_user.errors.should be_present
      @unreged_user.errors.on(:interested_in).should be_present
      response.should render_template "users/setup"
    end
  
    it "should not proceed without a birth_date" do
      post :setup, :user => @valid_attributes.except("birth_date(1i)", "birth_date(2i)", "birth_date(3i)")
      @unreged_user.errors.should be_present
      @unreged_user.errors.on(:birth_date).should be_present
      response.should render_template "users/setup"
    end
  
    it "should not proceed with a duplicate email address" do
      reged_guy = Factory(:registered_guy)
      post :setup, :user => @valid_attributes.merge(:email => reged_guy.email)
      @unreged_user.errors.should be_present
      @unreged_user.errors.on(:email).should be_present
      response.should render_template "users/setup"
    end
  
    it "should set the current user to registered with valid user params" do
      proc { post :setup, :user => @valid_attributes }.should change(@unreged_user, :registered?).from(false).to(true)
    end
  
    it "should send a welcome message to a new user with valid user params" do
      @unreged_user.visible_messages_to.should be_blank
      post :setup, :user => @valid_attributes
      @unreged_user.reload
      @unreged_user.visible_messages_to.should have(1).thing
      welcome_msg = @unreged_user.visible_messages_to.first
      welcome_msg.subject.should == "Welcome to Plenty of Tweeps!"
      welcome_msg.body.should include_text("Hi #{@unreged_user.login}")
    end

  end
  
  context "POST to :like" do
    
    it "should add a registered user to current_user.liked_users" do
      reged_guy = Factory(:registered_guy)
      @controller.stub(:current_user).and_return(reged_guy)
      reged_guy.stub(:closest_relationship).and_return(:location)    
      fake_authentication
    
      reged_guy.liked_users.should be_blank
      post :like, {:id => @f_24yo.login}
      response.should be_success
      reged_guy.reload
      reged_guy.liked_users.should == [@f_24yo]
    end
  
    it "should add an unregistered user to current_user.liked_users" do
      reged_girl = Factory(:registered_girl)
      @controller.stub(:current_user).and_return(reged_girl)
      fake_authentication

      reged_girl.liked_users.should be_blank
      User.find_by_login("garyvee").should be_blank

      reged_girl.stub(:get_twitter_user).and_return({"id" => 121231212, "screen_name" => "garyvee", "profile_image_url" => "http://whatever"})
      reged_girl.stub(:closest_relationship).and_return(:location)
      post :like, {:id => "garyvee"}
      response.should be_success
      garyvee = User.find_by_login("garyvee")
      garyvee.should be_present
      reged_girl.reload
      reged_girl.liked_users.should == [garyvee]
    end

  end
  
  it "should permit a user to update their email_on_new_message" do
    reged_guy = Factory(:registered_guy)
    reged_guy.email_on_new_message?.should == true
    @controller.stub(:current_user).and_return(reged_guy)
    post :email_settings, :user => { :email_on_new_message => "" }
    reged_guy.reload
    reged_guy.email_on_new_message?.should == false
  end
  
  context "GET to :random_profile" do
  
    it "should display a random female user for a straight guy" do
      reged_guy = Factory(:registered_guy)
      reged_girl = Factory(:registered_girl)
      controller.stub(:current_user).and_return(reged_guy)
      fake_authentication
    
      get :random_profile
      response.should be_success
      assigns[:user].gender.should == reged_guy.interested_in
      assigns[:user].interested_in.should == reged_guy.gender
      response.should include_text "Next Random User"
    end
  
    it "should display a random male user for a straight girl" do
      reged_guy = Factory(:registered_guy)
      reged_girl = Factory(:registered_girl)
      controller.stub(:current_user).and_return(reged_girl)
      fake_authentication
    
      get :random_profile
      response.should be_success
      assigns[:user].gender.should == reged_girl.interested_in
      assigns[:user].interested_in.should == reged_girl.gender
      response.should include_text "Next Random User"    
    end
  
    it "should display Ajaxified buttons to logged in users" do
      controller.stub(:current_user).and_return(Factory(:registered_guy))
      get :random_profile
      response.should be_success
      response.should have_tag("a#like[href=#]")
      response.should have_tag("a#message")
    end
  
  end
  
  context "POST to :fix_profile_image_url" do

    it "should fix a broken image url for a user that exists in our DB" do
      reged_guy = Factory(:registered_guy)

      FakeWeb.register_uri(:get,
                           "https://twitter.com/users/show/#{reged_guy.login}.json",
                           :body => %Q{{"profile_image_url":"http://a1.twimg.com/profile_images/51763742/techno_toque_normal.jpg"}})

      post :fix_profile_image_url, :username_with_broken_image => reged_guy.login, :image_id => "user-image-2382ZZ"
      response.should be_success
      response.should include_text "user_img.src = 'http://a1.twimg.com/profile_images/51763742/techno_toque_normal.jpg'"
      response.should include_text "user_img.onerror = ''"
      reged_guy.reload
      reged_guy.profile_image_url.should == "http://a1.twimg.com/profile_images/51763742/techno_toque_bigger.jpg"
    end
  
    it "should fix a broken image url for a user that doesn't exist in our DB" do
      FakeWeb.register_uri(:get,
                           "https://twitter.com/users/show/ev.json",
                           :body => %Q{{"profile_image_url":"http://a1.twimg.com/profile_images/51763742/techno_toque_normal.jpg"}})

      post :fix_profile_image_url, :username_with_broken_image => "ev", :image_id => "user-image-2382ZZ" 

      response.should be_success
      response.should include_text "user_img.src = 'http://a1.twimg.com/profile_images/51763742/techno_toque_normal.jpg'"
      response.should include_text "user_img.onerror = ''"
    end

  end

  it "should follow the username params[:id] on Twitter with a POST to :follow" do
    FakeWeb.register_uri(:post, "https://twitter.com/friendships/create/30sleeps.json", :body => "")
    reged_guy = Factory(:registered_guy)
    reged_guy.should_receive(:follow).once.with("30sleeps")
    @controller.stub(:current_user).and_return(reged_guy)
    post :follow, :id => "30sleeps"
  end
  
  it "should unfollow the username params[:id] on Twitter with a POST to :unfollow" do
    FakeWeb.register_uri(:post, "https://twitter.com/friendships/destroy/30sleeps.json", :body => "")
    reged_guy = Factory(:registered_guy)
    reged_guy.should_receive(:unfollow).once.with("30sleeps")
    @controller.stub(:current_user).and_return(reged_guy)
    post :unfollow, :id => "30sleeps"
  end
  
  context "tracking recently viewed users" do
    
    before :each do
      @reged_girl = Factory(:registered_girl)
      controller.stub(:current_user).and_return(@reged_girl)
    end
    
    it "should store the five most recently viewed users in session[:recently_viewed_users] with a GET to :show" do
      users = []
      6.times do
        users << Factory(:registered_girl)
      end

      session[:recently_viewed_users].should be_blank
      get :show, :id => users.first.login
      session[:recently_viewed_users].map { | u | u[:login] }.should == [users.first.login]

      users[1, 4].each do | u |
        get :show, :id => u.login
      end
      session[:recently_viewed_users].map { | u | u[:login] }.should == users.to(4).reverse.map { |u| u.login }
      
      get :show, :id => users[5].login
      session[:recently_viewed_users].map { | u | u[:login] }.should == users[1, 5].reverse.map { |u| u.login }
    end
    
    it "should not store duplicates in the recently viewed users" do
      reged_guy = Factory(:registered_guy)

      session[:recently_viewed_users].should be_blank
      get :show, :id => reged_guy.login
      session[:recently_viewed_users].map { | u | u[:login] }.should == [reged_guy.login]
      
      get :show, :id => reged_guy.login
      session[:recently_viewed_users].map { | u | u[:login] }.should == [reged_guy.login]
    end
    
    it "should not store the current_user in recently_viewed_users on a GET to :show" do
      session[:recently_viewed_users].should be_blank
      get :show, :id => @reged_girl.login
      session[:recently_viewed_users].should be_blank
    end
    
  end
  
  context "POST to :send_smile" do
    
    it "should call current_user.send_smile_and_notify, passing in the target user" do
      reged_guy = Factory(:registered_guy)
      reged_girl = Factory(:registered_girl)
      controller.stub(:current_user).and_return(reged_guy)
      
      reged_guy.should_receive(:send_smile_and_notify).once.with(reged_girl.login)
      post :send_smile, :id => reged_girl.login
    end
    
  end
  
  context "GET to :screen_name_autocomplete_source" do
    
    it "should return a list of screen names relevant to the current user, in JSON format" do
      reged_guy = Factory(:registered_guy)
      reged_guy.stub(:screen_name_autocomplete_source).and_return(["first", "second", "third"])
      controller.stub(:current_user).and_return(reged_guy)
      get :screen_name_autocomplete_source, :format => "json"
      response.should be_success
      response.body.should == '["first","second","third"]'
    end
    
  end
  
  protected

  def fake_authentication
    controller.stub(:login_required).and_return(true)
    controller.stub(:registration_required).and_return(true)
  end

end