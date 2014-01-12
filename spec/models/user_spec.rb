require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "An unregistered user (User#joined_on is blank)" do

  before(:each) do
    @unreged_user = Factory.build(:unregistered_user)
    fake_pot_human = Factory.create(:unregistered_user)
    User.stub!(:get_pot_human).and_return(fake_pot_human)
  end

  it "is valid without an email address" do
    @unreged_user.email.should be_blank
    @unreged_user.should be_valid
  end
  
  it "is valid without a gender" do
    @unreged_user.gender.should be_blank
    @unreged_user.should be_valid
  end
  
  it "is valid without a postal_code" do
    @unreged_user.postal_code.should be_blank
    @unreged_user.should be_valid
  end
  
  it "is valid without an interested_in" do
    @unreged_user.interested_in.should be_blank
    @unreged_user.should be_valid
  end
  
  it "is valid without a birth_date" do
    @unreged_user.birth_date.should be_blank
    @unreged_user.should be_valid
  end

  it "is valid without a min_age" do
    @unreged_user.min_age.should be_blank
    @unreged_user.should be_valid
  end

  it "is valid without a max_age" do
    @unreged_user.max_age.should be_blank
    @unreged_user.should be_valid
  end

  it "should become a registered user by calling User#register" do
    @unreged_user.should_not be_registered
    @unreged_user.register_and_send_welcome_message! :min_age => "20",
                                                     :max_age => "35",
                                                     :email => "whatever@blah.com",
                                                     :"birth_date(3i)" => "19",
                                                     :"birth_date(2i)" => "11",
                                                     :"birth_date(1i)" => "1978",
                                                     :interested_in => "F",
                                                     :gender => "M"
    @unreged_user.should be_registered
    @unreged_user.gender.should == "M"
    @unreged_user.birth_date.to_s.should == "1978-11-19"
  end

  it "should log an action once registered" do
    Action.find(:all).should be_blank
    @unreged_user.register_and_send_welcome_message! :min_age => "20",
                                                     :max_age => "35",
                                                     :email => "whatever@blah.com",
                                                     :"birth_date(3i)" => "19",
                                                     :"birth_date(2i)" => "11",
                                                     :"birth_date(1i)" => "1978",
                                                     :interested_in => "F",
                                                     :gender => "M"
    @unreged_user.notify_interested! 
    actions = Action.find(:all)
    actions.length.should == 1
    actions.first.item.should == @unreged_user
    actions.first.item_type.should == "User"
  end

end

describe "A registered user (User#joined_on is not blank)" do
  
  it "should be  *valid* without an email address" do
    reged_user = Factory.build(:registered_guy, :email => "")
    reged_user.should be_valid
  end

  it "should be invalid without a valid email address" do
    reged_user = Factory.build(:registered_guy, :email => "afsafas")
    reged_user.should_not be_valid
    reged_user.email = Factory.next(:email)
    reged_user.should be_valid
  end

  
  it "should be invalid without a gender" do
    reged_user = Factory.build(:registered_guy, :gender => "")
    reged_user.should_not be_valid
    reged_user.gender = "M"
    reged_user.should be_valid
  end
  
  it "should be invalid without a interested_in" do
    reged_user = Factory.build(:registered_guy, :interested_in => "")
    reged_user.should_not be_valid
    reged_user.interested_in = "F"
    reged_user.should be_valid
  end
  
  it "should be invalid without a birth_date" do
    reged_user = Factory.build(:registered_guy, :birth_date => "")
    reged_user.should_not be_valid
    reged_user.birth_date = 25.years.ago
    reged_user.should be_valid
  end
  
  it "should be invalid without a min_age" do
    reged_user = Factory.build(:registered_guy, :min_age => nil)
    reged_user.should_not be_valid
    reged_user.min_age = 25
    reged_user.should be_valid
  end
  
  it "should be invalid without a max_age" do
    reged_user = Factory.build(:registered_guy, :max_age => nil)
    reged_user.should_not be_valid
    reged_user.max_age = 30
    reged_user.should be_valid
  end
  
  it "should be at least 18 years old" do
    reged_user = Factory.build(:registered_girl, :birth_date => 17.years.ago.to_date)
    reged_user.should_not be_valid
    reged_user.errors.on(:birth_date).should == "must be 18 or older"
    reged_user.birth_date = 18.years.ago
    reged_user.should be_valid
  end
  
  it "should know its age" do
    reged_user = Factory.build(:registered_guy, :birth_date => 25.years.ago)
    reged_user.age.should == 25
  end

end

describe "A User instance" do
  include ActionController::TestProcess

  before(:each) do
    @user = Factory.create(:connector_guy)
    @f_28yo = Factory.create(:registered_girl, :birth_date => 28.years.ago)
    @f_24yo = Factory.create(:registered_girl, :birth_date => 24.years.ago)
  end
  
  it "should know its profile is complete only when User#description has been filled in " +
     "and at least one photo has been uploaded" do
    new_user = Factory.create(:registered_guy)
    new_user.description.should be_blank
    new_user.photos.should be_blank
    new_user.profile_complete?.should == false
    
    new_user.description = "some description"
    new_user.save!
    new_user.profile_complete?.should == false
    
    photo = Photo.create! :data => fixture_file_upload('files/test.jpg', 'image/jpeg', :binary),
                          :user_id => new_user.id
    photo.stub!(:save_attached_files).and_return true
    photo.save.should be_true
    
    new_user.reload
    new_user.profile_complete?.should == true
  end
  
  it "should provide a method to find nearby users" do
    matching_users = @user.find_nearby(:min_age => 25, :max_age => 30)
    matching_users.should == [@f_28yo]
    
    matching_users = @user.find_nearby(:min_age => 24, :max_age => 30)
    matching_users.should == [@f_28yo, @f_24yo]
  end
  
  it "should provide a paginated find nearby method" do
    matching_users_paginated = @user.paginate_find_nearby(:min_age => 24, :max_age => 30,
                                                          :results_per_page => 1,
                                                          :page => 1)
    matching_users_paginated.should be_instance_of MatchingUsersPaginated
    matching_users_paginated.current_page_results.should == [@f_28yo]
    
    matching_users_paginated = @user.paginate_find_nearby(:min_age => 24, :max_age => 30,
                                                          :results_per_page => 1,
                                                          :page => 2)
    matching_users_paginated.current_page_results.should == [@f_24yo]
    
    matching_users_paginated = @user.paginate_find_nearby(:min_age => 24, :max_age => 30)
    matching_users_paginated.current_page_results.should == [@f_28yo, @f_24yo]
  end
  
  it "should provide a method to count nearby users" do
    @user.count_nearby(:min_age => 25, :max_age => 30).should == 1
    @user.count_nearby(:min_age => 24, :max_age => 30).should == 2
  end
  
  it "should provide a paginated list of all Twitter friends" do
    user_with_friends = Factory.create(:registered_guy, :friends_count => 50)
    user_with_friends.stub!(:get_twitter_friends).and_return(nil)
    friends_paginated = user_with_friends.paginate_all_friends
    friends_paginated.should be_instance_of MatchingUsersPaginated
    friends_paginated.page.should == 1
    friends_paginated.results_per_page.should == 100
    friends_paginated.total_page_count.should == 1
    friends_paginated.has_next_page?.should == false
    friends_paginated.has_prev_page?.should == false
  end

  it "should provide a paginated list of only friends that have registered in PoT" do
    example_friend_of_user = Factory.create(:registered_girl, :birth_date => 25.years.ago)

    @user.stub!(:get_twitter_friend_ids).and_return([])
    friends_paginated = @user.paginate_only_reged_friends
    friends_paginated.should be_instance_of MatchingUsersPaginated
    friends_paginated.page.should == 1
    friends_paginated.results_per_page.should == 100
    friends_paginated.total_page_count.should == 1
    friends_paginated.current_page_results.should be_blank
    friends_paginated.has_next_page?.should == false
    friends_paginated.has_prev_page?.should == false
    
    @user.stub!(:get_twitter_friend_ids).and_return([example_friend_of_user.twitter_id])
    friends_paginated = @user.paginate_only_reged_friends
    friends_paginated.should be_instance_of MatchingUsersPaginated
    friends_paginated.page.should == 1
    friends_paginated.results_per_page.should == 100
    friends_paginated.total_page_count.should == 1
    friends_paginated.current_page_results.should == [example_friend_of_user]
    friends_paginated.has_next_page?.should == false
    friends_paginated.has_prev_page?.should == false
  end
  
  it "should provide a paginated list of all Twitter followers" do
    user_with_followers = Factory.create(:registered_guy, :followers_count => 230)
    user_with_followers.stub!(:get_twitter_followers).and_return(nil)
    followers_paginated = user_with_followers.paginate_all_followers
    followers_paginated.should be_instance_of MatchingUsersPaginated
    followers_paginated.page.should == 1
    followers_paginated.results_per_page.should == 100
    followers_paginated.total_page_count.should == 3
    followers_paginated.has_next_page?.should == true
    followers_paginated.has_prev_page?.should == false
    
    # Next page...
    followers_paginated = user_with_followers.paginate_all_followers(:page => 2)
    followers_paginated.should be_instance_of MatchingUsersPaginated
    followers_paginated.page.should == 2
    followers_paginated.results_per_page.should == 100
    followers_paginated.total_page_count.should == 3
    followers_paginated.has_next_page?.should == true
    followers_paginated.has_prev_page?.should == true
  end
  
  it "should provide a paginated list of only followers that have registered in PoT" do
    example_follower_of_user = Factory.create(:registered_girl, :birth_date => 25.years.ago)

    @user.stub!(:get_twitter_follower_ids).and_return([])
    followers_paginated = @user.paginate_only_reged_followers
    followers_paginated.should be_instance_of MatchingUsersPaginated
    followers_paginated.page.should == 1
    followers_paginated.results_per_page.should == 100
    followers_paginated.total_page_count.should == 1
    followers_paginated.current_page_results.should be_blank
    followers_paginated.has_next_page?.should == false
    followers_paginated.has_prev_page?.should == false
    
    @user.stub!(:get_twitter_follower_ids).and_return([example_follower_of_user.twitter_id])
    followers_paginated = @user.paginate_only_reged_followers
    followers_paginated.should be_instance_of MatchingUsersPaginated
    followers_paginated.page.should == 1
    followers_paginated.results_per_page.should == 100
    followers_paginated.total_page_count.should == 1
    followers_paginated.current_page_results.should == [example_follower_of_user]
    followers_paginated.has_next_page?.should == false
    followers_paginated.has_prev_page?.should == false
  end
  
  it "should provide a list of all Twitter users nearby" do
    reged_guy = Factory.create :registered_guy
    reged_guy.stub!(:get_nearby_tweeters).and_return(
      {"max_id"=>5107019031, "results"=> [
        {"created_at"=>"Fri, 23 Oct 2009 21:13:18 +0000", "profile_image_url"=>"http://a1.twimg.com/profile_images/238063234/hym_normal.jpg", "location"=>"Victoria, BC, Canada", "from_user"=>"itsHeyYouMedia", "text"=>"I posted 3 photos on Facebook in the album &quot;Photo Retouching&quot; http://bit.ly/c6WK1", "to_user_id"=>nil, "id"=>5107019031, "from_user_id"=>18354528, "iso_language_code"=>"en", "source"=>"&lt;a href=&quot;http://www.facebook.com/twitter&quot; rel=&quot;nofollow&quot;&gt;Facebook&lt;/a&gt;"},
        {"created_at"=>"Fri, 23 Oct 2009 21:13:15 +0000", "profile_image_url"=>"http://a1.twimg.com/profile_images/113490060/n562177563_9966_normal.jpg", "location"=>"Victoria, BC, Canada", "from_user"=>"AlphabetSalad", "text"=>"@mommadona He's a real prize, isn't he? Ick.", "to_user_id"=>2297717, "id"=>5107017752, "to_user"=>"mommadona", "from_user_id"=>48807256, "iso_language_code"=>"en", "source"=>"&lt;a href=&quot;http://www.tweetdeck.com/&quot; rel=&quot;nofollow&quot;&gt;TweetDeck&lt;/a&gt;"}
      ], "since_id"=>4925937431, "refresh_url"=>"?since_id=5107019031&q=", "next_page"=>"?page=2&max_id=5107019031&rpp=100&geocode=48.4275%2C-123.367259%2C50.0km&q=", "page"=>1, "results_per_page"=>100, "completed_in"=>0.111534, "warning"=>"adjusted since_id to 4925937431 (2009-10-16 21:00:00 UTC), requested since_id was older than allowed -- since_id removed for pagination.", "query"=>""}
    )
    all_twitter_users_nearby = reged_guy.paginate_all_twitter_users_nearby(:page => 1, :lat => 48.4275, :lng => -123.367259)
    all_twitter_users_nearby.should be_instance_of MatchingUsersPaginated
    all_twitter_users_nearby.page.should == 1
    all_twitter_users_nearby.results_per_page.should == 100
    all_twitter_users_nearby.current_page_results.size.should == 2
    first_matching_user = all_twitter_users_nearby.current_page_results.first
    first_matching_user.profile_image_url.should == "http://a1.twimg.com/profile_images/238063234/hym_bigger.jpg"
    first_matching_user.location.should == "Victoria, BC, Canada"
    first_matching_user.login.should == "itsHeyYouMedia"
    first_matching_user.latest_tweet.should == "I posted 3 photos on Facebook in the album &quot;Photo Retouching&quot; http://bit.ly/c6WK1"
  end
  
  it "should filter duplicate users out of the all Twitter users nearby results" do
    reged_guy = Factory.create :registered_guy
    reged_guy.stub!(:get_nearby_tweeters).and_return(
      {"max_id"=>5107019031, "results"=> [
        {"created_at"=>"Fri, 23 Oct 2009 21:13:18 +0000", "profile_image_url"=>"http://a1.twimg.com/profile_images/238063234/hym_normal.jpg", "location"=>"Victoria, BC, Canada", "from_user"=>"itsHeyYouMedia", "text"=>"I posted 3 photos on Facebook in the album &quot;Photo Retouching&quot; http://bit.ly/c6WK1", "to_user_id"=>nil, "id"=>5107019031, "from_user_id"=>18354528, "iso_language_code"=>"en", "source"=>"&lt;a href=&quot;http://www.facebook.com/twitter&quot; rel=&quot;nofollow&quot;&gt;Facebook&lt;/a&gt;"},
        {"created_at"=>"Fri, 23 Oct 2009 21:13:18 +0000", "profile_image_url"=>"http://a1.twimg.com/profile_images/238063234/hym_normal.jpg", "location"=>"Victoria, BC, Canada", "from_user"=>"itsHeyYouMedia", "text"=>"something else", "to_user_id"=>nil, "id"=>5107019032, "from_user_id"=>18354528, "iso_language_code"=>"en", "source"=>"&lt;a href=&quot;http://www.facebook.com/twitter&quot; rel=&quot;nofollow&quot;&gt;Facebook&lt;/a&gt;"},
        {"created_at"=>"Fri, 23 Oct 2009 21:13:15 +0000", "profile_image_url"=>"http://a1.twimg.com/profile_images/113490060/n562177563_9966_normal.jpg", "location"=>"Victoria, BC, Canada", "from_user"=>"AlphabetSalad", "text"=>"@mommadona He's a real prize, isn't he? Ick.", "to_user_id"=>2297717, "id"=>5107017752, "to_user"=>"mommadona", "from_user_id"=>48807256, "iso_language_code"=>"en", "source"=>"&lt;a href=&quot;http://www.tweetdeck.com/&quot; rel=&quot;nofollow&quot;&gt;TweetDeck&lt;/a&gt;"}
      ], "since_id"=>4925937431, "refresh_url"=>"?since_id=5107019031&q=", "next_page"=>"?page=2&max_id=5107019031&rpp=100&geocode=48.4275%2C-123.367259%2C50.0km&q=", "page"=>1, "results_per_page"=>100, "completed_in"=>0.111534, "warning"=>"adjusted since_id to 4925937431 (2009-10-16 21:00:00 UTC), requested since_id was older than allowed -- since_id removed for pagination.", "query"=>""}
    )
    all_twitter_users_nearby = reged_guy.paginate_all_twitter_users_nearby(:page => 1, :lat => 48.4275, :lng => -123.367259)
    all_twitter_users_nearby.should be_instance_of MatchingUsersPaginated
    all_twitter_users_nearby.page.should == 1
    all_twitter_users_nearby.results_per_page.should == 100
    all_twitter_users_nearby.current_page_results.size.should == 2
    all_twitter_users_nearby.current_page_results.first.login.should == "itsHeyYouMedia"
    all_twitter_users_nearby.current_page_results.second.login.should == "AlphabetSalad"
  end
    
  it "should be instantiable from a Twitter user hash, as return by twitter-auth" do
    user = User.new_from_twitter_auth_user_hash(TWITTER_AUTH_USER_HASH)
    user.twitter_id.should == 15597251
    user.login.should == "DaleCarnegie"
    user.profile_image_url.should == "http://a3.twimg.com/profile_images/236903911/DCT_logo_diamond_normal_bigger.jpg"
    user.url.should == "http://www.dalecarnegie.com"
    user.location.should == "U.S. and 75+ countries"
    user.description.should == "Dale Carnegie Training – The Leader In Workplace Learning and Development"
  end
  
  it "should be able to signal interest in another registered user" do
    @user.liked_users.should be_blank
    @user.like_and_notify(@f_24yo.login)
    @user.reload
    @user.liked_users.should == [@f_24yo]
  end
  
  it "should be able to signal interest in an *un*registered user" do
    User.find_by_login("garyvee").should be_blank
    @user.liked_users.should be_blank
    
    @user.stub!(:get_twitter_user).and_return({"id" => 121231212, "screen_name" => "garyvee", "profile_image_url" => "http://whatever"})
    @user.like_and_notify("garyvee")
    garyvee = User.find_by_login("garyvee")
    garyvee.should be_present
    @user.reload
    @user.liked_users.should == [garyvee]
  end  
  
  it "should return silently when like is called a second time with the same user, reg'd or unreg'd" do
    @user.stub!(:get_twitter_user).and_return({"id" => 123234343, "screen_name" => "SimoneKaminsky", "profile_image_url" => "http://whatever"})    
    @user.like_and_notify("SimoneKaminsky")
    lambda { @user.like_and_notify("SimoneKaminsky") }.should_not raise_error
    
    @user.stub!(:get_twitter_user).and_return({"id" => 121231212, "screen_name" => "garyvee", "profile_image_url" => "http://whatever"})    
    User.find_by_login("garyvee").should be_blank
    @user.like_and_notify("garyvee")
    lambda { @user.like_and_notify("garyvee") }.should_not raise_error
  end
  
  it "should know when it likes another user" do
    @user.likes?(@f_24yo.login).should == false
    @user.likes?(@f_24yo).should == false

    @user.like_and_notify(@f_24yo)
    @user.reload

    @user.likes?(@f_24yo.login).should == true
    @user.likes?(@f_24yo).should == true
  end
  
  it "should know which users like them (User#liked_by_users)" do
    @f_24yo.liked_by_users.should be_blank
    @user.like_and_notify(@f_24yo)
    @f_24yo.reload
    @f_24yo.liked_by_users.should == [@user]
  end
  
  it "should know its mutual admirers (User#mutual_admirers)" do
    reged_guy = Factory.create(:registered_guy)
    reged_girl_1 = Factory.create(:registered_girl)
    reged_girl_2 = Factory.create(:registered_girl)
    
    reged_guy.mutual_admirers.should be_blank
    reged_guy.like_and_notify reged_girl_1
    reged_guy.reload
    reged_guy.mutual_admirers.should be_blank
    
    reged_girl_1.like_and_notify reged_guy
    reged_guy.reload
    reged_guy.mutual_admirers.should == [reged_girl_1]
    
    reged_girl_2.like_and_notify reged_guy
    reged_guy.reload
    reged_guy.mutual_admirers.should == [reged_girl_1]
  end
  
  it "should know the closest relationship of friends, followers or else location. Testing friend relationship" do
    example_friend_of_user = Factory.create :registered_girl,
                     :twitter_id => "14019082",
                     :login => "melissa",
                     :birth_date => 24.years.ago,
                     :profile_image_url => "http://a1.twimg.com/profile_images/125633192/avatar2_bigger.jpg",
                     :description => "An uber geek who is obsessed with technology, education, search engines, start-ups, and China. Also in love with @johnerik."
    @current_user = Factory.create :registered_guy,
                     :twitter_id => "14174460",
                     :login => "bollenbach",
                     :birth_date => "1987-11-06",
                     :profile_image_url => "http://a1.twimg.com/profile_images/59392246/pub_bigger.jpg",
                     :description => "My name is Ryan Bollenbach and I'm a Web Designer for Tungle. I love mixing music, mainly Electrohouse, Minimal and Tech House."
    @current_user.stub!(:get_twitter_friend_ids).and_return([example_friend_of_user.twitter_id.to_i])
    @current_user.stub!(:get_twitter_follower_ids).and_return(nil)
    symbol_returned = @current_user.closest_relationship(example_friend_of_user.twitter_id)
    symbol_returned.should == :friend
  end

  it "should cache the twitter api calls to get_user_from_twitter_as_hash(screen_name)" do
    FakeWeb.register_uri(:get, "https://twitter.com/users/show/#{@user.login}.json", :body => "POO")  
    @user.get_user_from_twitter_as_hash(@user.login)
    Rails.cache.fetch("/users/show/#{@user.login}").should == "POO"
  end

  it "should cache all the Twitter friends when calling paginate." do
    user_with_friends = Factory.create(:registered_guy, :friends_count => 50)
    Rails.cache.fetch("/statuses/friends?cursor=-1&twitter_id=#{user_with_friends.twitter_id}").should be_nil
    FakeWeb.register_uri(:get, "https://twitter.com/statuses/friends.json?cursor=-1&twitter_id=#{user_with_friends.twitter_id}", :body => "")
    friends_paginated = user_with_friends.paginate_all_friends
    Rails.cache.fetch("/statuses/friends?cursor=-1&twitter_id=#{user_with_friends.twitter_id}").should == []
  end

  it "should cache all the Twitter followers when calling paginate." do
    user_with_followers = Factory.create(:registered_guy, :followers_count => 230)
    Rails.cache.fetch("/statuses/followers?page=1&twitter_id=#{user_with_followers.twitter_id}").should==nil
    FakeWeb.register_uri(:get, "https://twitter.com/statuses/followers.json?page=1&twitter_id=#{user_with_followers.twitter_id}", :body => "")
    followers_paginated = user_with_followers.paginate_all_followers
    Rails.cache.fetch("/statuses/followers?page=1&twitter_id=#{user_with_followers.twitter_id}").should==""
  end

  it "should cache list of only friends that have registered in PoT" do
    example_friend_of_user = Factory.create(:registered_girl, :birth_date => 25.years.ago)
    Rails.cache.fetch("/friends/ids?twitter_id=#{@user.twitter_id}").should==nil
    FakeWeb.register_uri(:get, "https://twitter.com/friends/ids.json?twitter_id=#{@user.twitter_id}", :body => "")
    friends_paginated = @user.paginate_only_reged_friends
    Rails.cache.fetch("/friends/ids?twitter_id=#{@user.twitter_id}").should==""    
  end

  it "should cache list of only followers that have registered in PoT" do
    example_follower_of_user = Factory.create(:registered_girl, :birth_date => 25.years.ago)
    Rails.cache.fetch("/followers/ids?twitter_id=#{@user.twitter_id}").should==nil
    FakeWeb.register_uri(:get, "https://twitter.com/followers/ids.json?twitter_id=#{@user.twitter_id}", :body => "")
    followers_paginated = @user.paginate_only_reged_followers
    Rails.cache.fetch("/followers/ids?twitter_id=#{@user.twitter_id}").should==""    
  end
  
  it "should know if it follows another user" do
    reged_guy = Factory.create(:registered_guy)
    reged_girl = Factory.create(:registered_girl)
    
    FakeWeb.register_uri(:get, "https://twitter.com/friendships/exists.json?user_a=#{reged_guy.login}&user_b=#{reged_girl.login}", :body => "false")
    reged_guy.follows?(reged_girl).should == false
    
    FakeWeb.register_uri(:get, "https://twitter.com/friendships/exists.json?user_a=#{reged_guy.login}&user_b=#{reged_girl.login}", :body => "true")
    reged_guy.follows?(reged_girl).should == true
  end
  
  context "User#send_smile_and_notify(target_user)" do

    before :each do
      @source_user = Factory(:connector_guy)
      @target_user = Factory(:registered_girl)
      @source_user.stub(:get_twitter_user).and_return({"id" => 121231212, "screen_name" => "garyvee", "profile_image_url" => "http://whatever"})
      ActionMailer::Base.deliveries = []
    end
    
    it "should create a smile from the source_user to a registered target_user" do
      proc { @source_user.send_smile_and_notify(@target_user.login) }.should change(Smile, :count).by(1)
    end
    
    it "should create a smile from the source_user to an unregistered target_user" do
      User.find_by_login("garyvee").should be_blank
      proc { @source_user.send_smile_and_notify("garyvee") }.should change(Smile, :count).by(1)
      User.find_by_login("garyvee").should be_present
    end

    it "should not create a new smile if the target_user hasn't yet 'seen' (i.e. deleted) the last smile" do
      proc { @source_user.send_smile_and_notify(@target_user.login) }.should change(Smile, :count).by(1)
      proc { @source_user.send_smile_and_notify(@target_user.login) }.should_not change(Smile, :count)
    end
    
    it "should not send another email notification if the target user hasn't yet 'seen' the last smile" do
      ActionMailer::Base.deliveries.should be_blank
      proc { @source_user.send_smile_and_notify(@target_user.login) }.should change(Smile, :count).by(1)
      ActionMailer::Base.deliveries.should have(1).thing
      proc { @source_user.send_smile_and_notify(@target_user.login) }.should_not change(Smile, :count)
      ActionMailer::Base.deliveries.should have(1).thing
    end
    
    it "should create a new smile if the target_user *has* seen (i.e. deleted) the last smile" do
      Smile.all.should be_blank
      proc { @source_user.send_smile_and_notify(@target_user.login) }.should change(Smile, :count).by(1)
      Smile.first.seen!
      proc { @source_user.send_smile_and_notify(@target_user.login) }.should change(Smile, :count).by(1)
    end
    
    it "should send another email notification if the target user *has* seen (i.e. deleted) the last smile" do
      Smile.all.should be_blank
      proc { @source_user.send_smile_and_notify(@target_user.login) }.should change(ActionMailer::Base.deliveries, :count).by(1)
      Smile.first.seen!
      proc { @source_user.send_smile_and_notify(@target_user.login) }.should change(ActionMailer::Base.deliveries, :count).by(1)
    end
    
    it "should notify the target_user on Twitter if they are an unregistered user" do
      User.find_by_login("garyvee").should be_blank
      # Two notifications sent in total. One is a "sorry for bothering you" tweet.
      User.should_receive(:send_tweet).with(%r{@garyvee.*sent you a smile.*In case you're curious.*http://.*/recent})
      User.should_receive(:send_tweet).with(%r{@garyvee P\.S\.})
      @source_user.send_smile_and_notify("garyvee")
    end
    
    it "should notify an unregistered target_user user on Twitter only the first time they " +
       "receive a smile" do
      another_user = Factory(:registered_girl)

      User.find_by_login("garyvee").should be_blank
      # Two notifications sent in total. One is a "sorry for bothering you" tweet.
      User.should_receive(:send_tweet).twice
      @source_user.send_smile_and_notify("garyvee")
      another_user.send_smile_and_notify("garyvee")
    end
    
    it "should notify the target_user on Twitter if they are registered, but haven't provided an email address" do
      @target_user.update_attributes(:email => "")
      User.should_receive(:send_tweet).once
      Emailer.should_not_receive(:deliver_smile_notification)
      @source_user.send_smile_and_notify(@target_user.login)
    end
    
    it "should notify the target_user by email if they provided an email address" do
      @target_user.email.should be_present
      User.should_not_receive(:send_tweet)
      Emailer.should_receive(:deliver_smile_notification).once.with(@source_user, @target_user, :location)
      @source_user.send_smile_and_notify(@target_user.login)
    end
    
  end
  
  context "User#notify_interested!" do
    
    before(:each) do
      @reged_guy = Factory(:registered_guy)
      @newly_reged_girl = Factory(:registered_girl)
      ActionMailer::Base.deliveries = []
    end
    
    it "should notify users that have sent a smile to this user" do
      @reged_guy.send_smile_and_notify(@newly_reged_girl)
      
      Emailer.should_receive(:deliver_smile_recipient_joined_notification).once.with(@newly_reged_girl, @reged_guy)
      @newly_reged_girl.notify_interested!
      ActionMailer::Base.deliveries.should have(1).thing
    end
    
    it "should notify users that have liked this user" do
      @reged_guy.like_and_notify(@newly_reged_girl)
      
      Emailer.should_receive(:deliver_liked_user_joined_notification).once.with(@newly_reged_girl, @reged_guy)
      @newly_reged_girl.notify_interested!
      ActionMailer::Base.deliveries.should have(1).thing
    end
    
  end
  
  context "User#has_sent_an_unseen_smile_to?(target_user)" do
    
    before :each do
      @reged_guy = Factory(:registered_guy)
      @reged_girl = Factory(:registered_girl)
    end
    
    it "should return true if source_user has sent a smile to target_user " +
       "and the smile hasn't been deleted yet" do
      @reged_guy.has_sent_an_unseen_smile_to?(@reged_girl).should == false
      @reged_guy.send_smile_and_notify(@reged_girl)
      @reged_guy.has_sent_an_unseen_smile_to?(@reged_girl).should == true
    end
    
    it "should return false if the source_user sent a smile to target_user " +
       "and the smile has been deleted" do
      @reged_guy.send_smile_and_notify(@reged_girl)
      @reged_guy.has_sent_an_unseen_smile_to?(@reged_girl).should == true
      @reged_guy.smiles_sent.first.seen!
      @reged_guy.has_sent_an_unseen_smile_to?(@reged_girl).should == false
    end
    
  end

  context "User#number_of_smiles_sent_to(target_user)" do
    
    it "should return the count of smiles sent to the target_user, including deleted" do
      reged_guy = Factory(:registered_guy)
      reged_girl = Factory(:registered_girl)
      
      reged_guy.number_of_smiles_sent_to(reged_girl).should == 0
      reged_guy.send_smile_and_notify(reged_girl)
      reged_guy.number_of_smiles_sent_to(reged_girl).should == 1
      Smile.first.seen!
      reged_guy.number_of_smiles_sent_to(reged_girl).should == 1
      reged_guy.send_smile_and_notify(reged_girl)
      reged_guy.number_of_smiles_sent_to(reged_girl).should == 2
    end
    
  end
  
  context "User#friend_screen_names" do
    
    it "should return a list of the screen names of Twitter users the user follows" do
      registered_guy = Factory(:registered_guy)
      registered_guy.stub(:get_twitter_friends).and_return([{"screen_name" => "alicia_CHt"}, {"screen_name" => "JohnBaku"}])
      registered_guy.friend_screen_names.should == ["alicia_CHt", "JohnBaku"]
    end
    
  end
  
  context "User#screen_name_autocomplete_source" do
    
    before :each do
      @reged_guy = Factory(:registered_guy)
      @reged_guy.stub(:get_twitter_friends).and_return([])
      @reged_guy.screen_name_autocomplete_source.should be_blank
    end
        
    it "should include usernames of people you follow" do
      @reged_guy.stub(:get_twitter_friends).and_return([{"screen_name" => "alicia_CHt"}, {"screen_name" => "MarkRainer"}])
      @reged_guy.screen_name_autocomplete_source.should == ["alicia_CHt", "MarkRainer"]
    end
    
    it "should include usernames of people you like" do
      liked_user_1 = Factory(:registered_girl, :login => "liked_1")
      liked_user_2 = Factory(:registered_girl, :login => "liked_2")
      liked_user_3 = Factory(:registered_girl, :login => "liked_3")
      
      @reged_guy.stub(:liked_users).and_return([liked_user_1, liked_user_2, liked_user_3])
      @reged_guy.screen_name_autocomplete_source.should == %w(liked_1 liked_2 liked_3)
    end
    
    it "should include usernames of people that have liked you" do
      liked_by_user_1 = Factory(:registered_girl, :login => "liked_by_1")
      liked_by_user_2 = Factory(:registered_girl, :login => "liked_by_2")
      
      @reged_guy.stub(:liked_by_users).and_return([liked_by_user_1, liked_by_user_2])
      @reged_guy.screen_name_autocomplete_source.should == %w(liked_by_1 liked_by_2)
    end
    
    it "should include usernames of people you've smiled at" do
      smiled_at_user_1 = Factory(:registered_girl, :login => "smiled_at_1")
      smiled_at_user_2 = Factory(:registered_girl, :login => "smiled_at_2")
      smiled_at_user_3 = Factory(:registered_girl, :login => "smiled_at_3")
      
      @reged_guy.stub(:smiled_at_users).and_return([smiled_at_user_1, smiled_at_user_2, smiled_at_user_3])
      @reged_guy.screen_name_autocomplete_source.should == %w(smiled_at_1 smiled_at_2 smiled_at_3)
    end
    
    it "should include usernames of people that have smiled at you" do
      smiled_at_by_user_1 = Factory(:registered_girl, :login => "smiled_at_by_1")
      smiled_at_by_user_2 = Factory(:registered_girl, :login => "smiled_at_by_2")
      smiled_at_by_user_3 = Factory(:registered_girl, :login => "smiled_at_by_3")
      
      @reged_guy.stub(:smiled_at_by_users).and_return([smiled_at_by_user_1, smiled_at_by_user_2, smiled_at_by_user_3])
      @reged_guy.screen_name_autocomplete_source.should == %w(smiled_at_by_1 smiled_at_by_2 smiled_at_by_3)
    end
    
  end
  
  context "User#daily_smile_limit_reached?" do
  
    before :all do
      @introvert_smile_limit = INTROVERT.daily_smile_limit
      @introvert_smile_limit.should be > 0
      
      @connector_smile_limit = CONNECTOR.daily_smile_limit
      @connector_smile_limit.should be > 0
    end
    
    before :each do
      @introvert = Factory(:registered_guy, :account_type => INTROVERT.account_type)
      @connector = Factory(:connector_guy)
    end
    
    it "should return false when an Introvert account has not sent any smiles today" do
      @introvert.smiles_sent.should be_blank
      @introvert.daily_smile_limit_reached?.should == false
    end
    
    it "should return true when an Introvert has sent " +
       "INTROVERT.daily_smile_limit smiles today" do
      @introvert_smile_limit.times { Factory(:smile, :source_user_id => @introvert.id) }
      @introvert.smiles_sent.count.should == @introvert_smile_limit
      @introvert.daily_smile_limit_reached?.should == true
    end
    
    it "should return false when a Connector account has sent fewer than " +
       "CONNECTOR.daily_smile_limit smiles today" do
      Factory(:smile, :source_user_id => @connector.id)
      @connector.smiles_sent.count.should be < CONNECTOR.daily_smile_limit
      @connector.smiles_sent.count.should == 1      
    end
       
    it "should return true when a Connector has sent CONNECTOR.daily_smile_limit " +
       "smiles today" do
      @connector_smile_limit.times { Factory(:smile, :source_user_id => @connector.id) }
      @connector.smiles_sent.count.should == @connector_smile_limit
      @connector.daily_smile_limit_reached?.should == true
    end
    
  end


  context "User#daily_message_limit_reached?" do
  
    before :all do
      @introvert_message_limit = INTROVERT.daily_message_limit
      @introvert_message_limit.should be > 0
      
      @connector_message_limit = CONNECTOR.daily_message_limit
      @connector_message_limit.should be > 0
    end
    
    before :each do
      @introvert = Factory(:registered_guy, :account_type => INTROVERT.account_type)
      @connector = Factory(:connector_guy)
    end
    
    it "should return false when an Introvert account has not sent any messages today" do
      @introvert.messages_from.should be_blank
      @introvert.daily_message_limit_reached?.should == false
    end
    
    it "should return true when an Introvert has sent INTROVERT.daily_message_limit messages today" do
      @introvert_message_limit.times { Factory(:message, :from_user_id => @introvert.id) }
      @introvert.messages_from.count.should == @introvert_message_limit
      @introvert.daily_message_limit_reached?.should == true
    end
    
    it "should return false when a Connector account has sent fewer than " +
       "CONNECTOR.daily_message_limit messages today" do
      Factory(:message, :from_user_id => @connector.id)
      @connector.messages_from.count.should be < @connector_message_limit
      @connector.messages_from.count.should == 1      
    end
       
    it "should return true when a Connector has sent CONNECTOR.daily_message_limit " +
       "messages today" do
      @connector_message_limit.times { Factory(:message, :from_user_id => @connector.id) }
      @connector.messages_from.count.should == @connector_message_limit
      @connector.daily_message_limit_reached?.should == true
    end
    
  end

  context "User#daily_like_profile_limit_reached?" do
  
    before :all do
      @introvert_like_profile_limit = INTROVERT.daily_like_profile_limit
      @introvert_like_profile_limit.should be > 0
      
      @connector_like_profile_limit = CONNECTOR.daily_like_profile_limit
      @connector_like_profile_limit.should be > 0
    end
    
    before :each do
      @introvert = Factory(:registered_guy, :account_type => INTROVERT.account_type)
      @connector = Factory(:connector_guy)
    end
    
    it "should return false when an Introvert account has not liked any profiles today" do
      @introvert.liked_users.should be_blank
      @introvert.daily_like_profile_limit_reached?.should == false
    end
    
    it "should return true when an Introvert has liked INTROVERT.daily_like_profile_limit profiles today" do
      @introvert_like_profile_limit.times { Factory(:user_like, :source_user_id => @introvert.id) }
      @introvert.liked_users.count.should == @introvert_like_profile_limit
      @introvert.daily_like_profile_limit_reached?.should == true
    end
    
    it "should return false when a Connector account has liked fewer than " +
       "CONNECTOR.daily_like_profile_limit profiles today" do
      Factory(:user_like, :source_user_id => @connector.id)
      @connector.liked_users.count.should be < @connector_like_profile_limit
      @connector.liked_users.count.should == 1      
    end
       
    it "should return true when a Connector has liked CONNECTOR.daily_like_profile_limit " +
       "profiles today" do
      @connector_like_profile_limit.times { Factory(:user_like, :source_user_id => @connector.id) }
      @connector.liked_users.count.should == @connector_like_profile_limit
      @connector.daily_like_profile_limit_reached?.should == true
    end
    
  end
  
  context "User#photo_upload_limit_reached?" do
  
    before :all do
      @introvert_photo_upload_limit = INTROVERT.photo_upload_limit
      @introvert_photo_upload_limit.should be > 0
      
      @connector_photo_upload_limit = CONNECTOR.photo_upload_limit
      @connector_photo_upload_limit.should be > 0
    end
    
    before :each do
      @introvert = Factory(:registered_guy, :account_type => INTROVERT.account_type)
      @connector = Factory(:connector_guy)
    end
    
    it "should return false when an Introvert account has not uploaded any photos" do
      @introvert.photos.should be_blank
      @introvert.photo_upload_limit_reached?.should == false
    end
    
    it "should return true when an Introvert has uploaded INTROVERT.photo_upload_limit photos" do
      @introvert_photo_upload_limit.times { Factory(:photo, :user_id => @introvert.id) }
      @introvert.photos.count.should == @introvert_photo_upload_limit
      @introvert.photo_upload_limit_reached?.should == true
    end
    
    it "should return false when a Connector account has uploaded fewer than " +
       "CONNECTOR.photo_upload_limit photos" do
      Factory(:photo, :user_id => @connector.id)
      @connector.photos.count.should be < @connector_photo_upload_limit
      @connector.photos.count.should == 1      
    end
       
    it "should return true when a Connector has uploaded CONNECTOR.photo_upload_limit photos" do
      @connector_photo_upload_limit.times { Factory(:photo, :user_id => @connector.id) }
      @connector.photos.count.should == @connector_photo_upload_limit
      @connector.photo_upload_limit_reached?.should == true
    end
    
  end
  
  context "User#grant_introvert_access" do
    
    before(:each) do
      @connector_guy = Factory(:connector_guy)
      @connector_guy.paid_until.should be_present
      @connector_guy.months_remaining.should be_present
      @connector_guy.account_type.should == "C"
      
      @connector_guy.grant_introvert_access
    end
    
    it "should set #account_type to 'I'" do
      @connector_guy.account_type.should == 'I'
    end
    
    it "should set #paid_until to nil" do
      @connector_guy.paid_until.should be_nil
    end
    
    it "should set #months_remaining to nil" do
      @connector_guy.months_remaining.should be_nil
    end
    
  end
  
  context "User#grant_connector_access_for" do
    
    before(:each) do
      @introvert_guy = Factory(:introvert_guy)
    end
    
    it "should raise an ArgumentError if the time period is not at least 30 days in the future" do
      proc do
        @introvert_guy.grant_connector_access_for 22.days
      end.should raise_error ArgumentError, "time period for account extension must be at least 30 days"
    end
    
    it "should set the account_type to 'C' and set paid_until the passed-in time period into the future" do
      @introvert_guy.grant_connector_access_for 30.days
      @introvert_guy.account_type.should == "C"
      @introvert_guy.paid_until.to_date.should == Date.today + 30.days
      @introvert_guy.months_remaining.should == 0
    end
    
    it "should set #months_remaining to 2, and #paid_until to 30 days in the future, " +
       "when a time period of 3.months is passed in" do
      @introvert_guy.months_remaining.should be_blank
      @introvert_guy.grant_connector_access_for 3.months
      @introvert_guy.paid_until.to_date.should == Date.today + 30.days
      @introvert_guy.months_remaining.should == 2
    end

  end
  
  context "User#grant_social_skydiver_access_for" do
    
    before(:each) do
      @introvert_guy = Factory(:introvert_guy)
    end
    
    it "should raise an ArgumentError if the time period is not at least 30 days in the future" do
      proc do
        @introvert_guy.grant_social_skydiver_access_for 22.days
      end.should raise_error ArgumentError, "time period for account extension must be at least 30 days"
    end
    
    it "should set the account_type to 'S' and set paid_until the passed-in time period into the future" do
      @introvert_guy.grant_social_skydiver_access_for 30.days
      @introvert_guy.account_type.should == "S"
      @introvert_guy.paid_until.to_date.should == Date.today + 30.days
      @introvert_guy.months_remaining.should == 0
    end
    
    it "should set #months_remaining to 2, and #paid_until to 30 days in the future, " +
       "when a time period of 3.months is passed in" do
      @introvert_guy.months_remaining.should be_blank
      @introvert_guy.grant_social_skydiver_access_for 3.months
      @introvert_guy.paid_until.to_date.should == Date.today + 30.days
      @introvert_guy.months_remaining.should == 2
    end

  end
  
  context "User#profile_viewed_by_users.last_10_unique" do
    
    before(:each) do
      @viewed_girl = Factory(:registered_guy)
      @other_users = []
      12.times { @other_users << Factory(:registered_girl) }
      @other_users.each { |other_user| @viewed_girl.profile_viewed_by_users << other_user }
    end
    
    it "should return the last 10 users who viewed a user's profile" do
      @viewed_girl.profile_viewed_by_users.last_10_unique.should == @other_users[2..11].reverse
    end
    
    it "should include only unique results in those last 10 users" do
      @viewed_girl.profile_viewed_by_users << @other_users[0]
      @viewed_girl.profile_viewed_by_users << @other_users[0]
      @viewed_girl.profile_viewed_by_users.last_10_unique.should == (@other_users[3..11] + [@other_users[0]]).reverse
    end
    
  end

end

describe "User pagination" do
  
  before(:each) do
    @g_30yo = Factory(:registered_guy, :birth_date => 30.years.ago)
    @g_21yo = Factory(:registered_guy, :birth_date => 21.years.ago)
    @f_24yo = Factory(:registered_girl, :birth_date => 24.years.ago)
    @f_28yo = Factory(:registered_girl, :birth_date => 28.years.ago)
  end
  
  it "should provide a find method which accepts :conditions, :results_per_page, and :page and returns a MatchingUsersPaginated object" do
    matching_users_paginated = MatchingUsersPaginator.find :conditions => "birth_date <= '1973-09-23'",
                                                           :results_per_page => 1,
                                                           :page => 2
                                                           
    matching_users_paginated.should be_instance_of MatchingUsersPaginated
    matching_users_paginated.results_per_page.should == 1
    matching_users_paginated.page.should == 2
    matching_users_paginated.conditions.should == "birth_date <= '1973-09-23'"
  end
  
  it "return a list of matching results for only the current page" do
    matching_users_paginated = MatchingUsersPaginator.find :conditions => {:gender => "F"}
    current_page_results = matching_users_paginated.current_page_results
    current_page_results.should == [@f_24yo, @f_28yo]
    
    matching_users_paginated = MatchingUsersPaginator.find :conditions => {:gender => "F"},
                                                           :results_per_page => 1,
                                                           :page => 1
    current_page_results = matching_users_paginated.current_page_results
    current_page_results.should == [@f_24yo]
    
    matching_users_paginated = MatchingUsersPaginator.find :conditions => {:gender => "F"},
                                                           :results_per_page => 1,
                                                           :page => 2
   current_page_results = matching_users_paginated.current_page_results
   current_page_results.should == [@f_28yo]
  end
  
  it "should provide :total_results_count, :total_page_count, :has_next_page? and :has_prev_page?" do
    matching_users_paginated = MatchingUsersPaginator.find :results_per_page => 1
    matching_users_paginated.total_results_count.should == 4
    matching_users_paginated.total_page_count.should == 4
    matching_users_paginated.has_next_page?.should == true
    matching_users_paginated.has_prev_page?.should == false
    
    matching_users_paginated = MatchingUsersPaginator.find :results_per_page => 1,
                                                           :page => 3
    matching_users_paginated.total_results_count.should == 4
    matching_users_paginated.total_page_count.should == 4
    matching_users_paginated.has_next_page?.should == true
    matching_users_paginated.has_prev_page?.should == true
    
    matching_users_paginated = MatchingUsersPaginator.find :results_per_page => 2,
                                                           :page => 2
    matching_users_paginated.total_results_count.should == 4
    matching_users_paginated.total_page_count.should == 2
    matching_users_paginated.has_next_page?.should == false
    matching_users_paginated.has_prev_page?.should == true
  end

end

describe "A GEO Search" do

  it "should return the correct lat longs and city name object when searching for Zama City" do
    location = Geokit::GeoLoc.new :country_code => "CA",:state => "AB",:city=> "Mackenzie No. 23",:lat=> 59.166031,:lng=> -118.739829,:zip=> nil
    location.precision = "city"
    location.success=true
    GeoSearch.stub!(:geocode_search).and_return(location)
    locations = GeoSearch.find_nearby_locations :search_text=>"Zama City",:country_code=>"CA"
    locations.length.should==1
    locations[0].lat.to_s().should=="59.166031"
    locations[0].lng.to_s().should=="-118.739829"
    locations[0].city.should=="Mackenzie No. 23"
  end

  it "should return the correct lat longs and city name object when searching for Vancouver" do
    location = Geokit::GeoLoc.new :country_code => "CA",:state => "BC",:city=> "Vancouver",:lat=> 49.263588,:lng=> -123.138565,:zip=> nil
    location.precision = "city"
    location.success=true
    GeoSearch.stub!(:geocode_search).and_return(location)
    locations = GeoSearch.find_nearby_locations :search_text=>"Vancouver",:country_code=>"CA"
    locations.length.should==1
    locations[0].lat.to_s().should=="49.263588"
    locations[0].lng.to_s().should=="-123.138565"
    locations[0].city.should=="Vancouver"
  end

  it "should return the correct lat longs and city name object when searching for V6H1P5" do
    location = Geokit::GeoLoc.new :country_code => "CA",:state => "BC",:city=> nil,:lat=> 49.258887,:lng=> -123.130339,:zip=> "V6H1P5"
    location.precision = "zip"
    location.success=true
    GeoSearch.stub!(:geocode_search).and_return(location)
    
    reverse_location = Geokit::GeoLoc.new :country_code => "CA",:state => "BC",:city=> "Vancouver",:lat=> 49.258887,:lng=> -123.130339
    reverse_location.precision = "address"
    reverse_location.success=true
    GeoSearch.stub!(:geocode_from_lat_long).and_return(reverse_location)
    locations = GeoSearch.find_nearby_locations :search_text=>"V6H1P5"
    locations.length.should== 1
    locations[0].lat.to_s().should== "49.258887"
    locations[0].lng.to_s().should== "-123.130339"
    locations[0].city.should== "Vancouver"
  end

  it "should return multiple results when searching for Springfield" do
    geoloc = Geokit::GeoLoc.new :country_code => "US",:state => "BC",:city=> nil,:lat=> 49.258887,:lng=> -123.130339,:zip=> "V6H1P5"
    geoloc.success=true
    geoloc.all.push(Geokit::GeoLoc.new :country_code => "US",:state => "BC",:city=> "Springfield",:lat=> 49.258887,:lng=> -123.130339,:zip=> "V6H1P5")
    geoloc.all.push(Geokit::GeoLoc.new :country_code => "US",:state => "BC",:city=> "Springfield",:lat=> 49.258887,:lng=> -123.130339,:zip=> "V6H1P5")
    geoloc.all.push(Geokit::GeoLoc.new :country_code => "US",:state => "BC",:city=> "Springfield",:lat=> 49.258887,:lng=> -123.130339,:zip=> "V6H1P5")
    geoloc.all.push(Geokit::GeoLoc.new :country_code => "US",:state => "BC",:city=> "Springfield",:lat=> 49.258887,:lng=> -123.130339,:zip=> "V6H1P5")
    geoloc.all.push(Geokit::GeoLoc.new :country_code => "US",:state => "BC",:city=> "Springfield",:lat=> 49.258887,:lng=> -123.130339,:zip=> "V6H1P5")
    geoloc.all.push(Geokit::GeoLoc.new :country_code => "US",:state => "CO",:city=> "Springfield",:lat=> 49.258887,:lng=> -123.130339,:zip=> "V6H1P5")
    geoloc.all.push(Geokit::GeoLoc.new :country_code => "US",:state => "IL",:city=> "Springfield",:lat=> 49.258887,:lng=> -123.130339,:zip=> "V6H1P5")
    geoloc.all[1].precision="city"
    geoloc.all[2].precision="city"
    geoloc.all[3].precision="city"
    geoloc.all[4].precision="city"
    geoloc.all[5].precision="city"
    geoloc.all[6].precision="city"
    geoloc.all[7].precision="city"    
    GeoSearch.stub!(:geocode_search).and_return(geoloc)
    locations = GeoSearch.find_nearby_locations :search_text=>"Springfield", :bias=>"US"
    locations.length.should== 7
  end
end