require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MessagesController do
  
  integrate_views
  
  before :each do
    Rails.cache.delete("recently_online_users")
  end
  
  it "should set recently online users with an authenticated GET to :index" do
    reged_guy = Factory.create(:registered_guy)
    @controller.stub!(:current_user).and_return(reged_guy)
    
    get :index
    assigns["recently_online_users"].should == [reged_guy]
  end
  
  it "should render a 404 when an unpaid member tries to view a message to them from " +
     "someone with whom they are not a mutual admirer" do
    message = Factory.create :message
    to_user = message.to_user
    from_user = message.from_user
    # This is a bizarro hack needed to make the stubbing actually work.
    # I don't fully understand it, but I'm pretty sure it's due
    # to the association object message.to_user not being the same
    # as the object that is "self" when "paid_member?" is called
    # inside the code path being tested.
    to_user = User.find(to_user.id)
    to_user.stub!(:paid_member?).and_return(false)
    (from_user.likes?(to_user) && to_user.likes?(from_user)).should == false
    @controller.stub!(:current_user).and_return(to_user)
    get :show, :id => message.id
    
    response.status.should == "404 Not Found"
  end
  
  it "should always render a message to the user that sent it" do
    message = Factory.create :message
    @controller.stub!(:current_user).and_return(message.from_user)
    get :show, :id => message.id
    
    response.should be_success
    response.should render_template "messages/show"
  end
  
  it "should render a message to an unpaid member when they are the recipient " +
     "and they a mutual admirer of the sender" do
    message = Factory.create :message
    to_user = message.to_user
    from_user = message.from_user
    from_user.like_and_notify to_user
    to_user.like_and_notify from_user
    
    to_user.reload
    to_user.mutual_admirers.should == [from_user]
    
    @controller.stub!(:current_user).and_return(message.to_user)
    get :show, :id => message.id
    
    response.should be_success
    response.should render_template "messages/show"
  end
  
  it "should mark the message read when its recipient issues a GET to :show" do
    message = Factory.create :message
    to_user = message.to_user
    from_user = message.from_user
    from_user.like_and_notify to_user
    to_user.like_and_notify from_user
    
    to_user.reload
    to_user.mutual_admirers.should == [from_user]
  
    @controller.stub!(:current_user).and_return(message.to_user)
  
    message.should be_unread
    get :show, :id => message.id
    response.should be_success
    message.reload
    message.should_not be_unread
  end
  
  it "should leave the message UNread when its sender issues a GET to :show" do
    message = Factory.create :message
    to_user = message.to_user
    from_user = message.from_user
    from_user.like_and_notify to_user
    to_user.like_and_notify from_user
    
    to_user.reload
    to_user.mutual_admirers.should == [from_user]
  
    @controller.stub!(:current_user).and_return(message.from_user)
  
    message.should be_unread
    get :show, :id => message.id
    response.should be_success
    message.reload
    message.should be_unread    
  end
  
  it "should return a 404 when trying to render a message belonging to someone other than the current user" do
    message = Factory.create :message
    another_user = Factory.create :registered_guy
    another_user.should_not == message.from_user
    another_user.should_not == message.to_user
  
    @controller.stub!(:current_user).and_return(another_user)
    get :show, :id => message.id
    
    response.status.should == "404 Not Found"
  end
  
  it "should return a 404 when no such message exists" do
    non_existent_id = 238938031
    Message.exists?(:id => non_existent_id).should == false
    
    @controller.stub!(:current_user).and_return(Factory.create :registered_guy)
    get :show, :id => non_existent_id
    
    response.status.should == "404 Not Found"
  end
  
  it "should require a subject when POST'ing to :send_msg_to" do
    sender = Factory.create :registered_guy
    receiver = Factory.create :registered_girl
    @controller.stub!(:current_user).and_return(sender)
  
    sender.messages_from.should be_blank
    post :send_msg_to, :message => {:subject => "", :body => "test body"}, :login => receiver.login
    sender.reload
    sender.messages_from.should be_blank
    response.should be_success
    response.should render_template "messages/send_msg_to"
    assigns[:message].body.should == "test body"
  end
  
  it "should require a body when POST'ing to :send_msg_to" do
    sender = Factory.create :registered_guy
    receiver = Factory.create :registered_girl
    @controller.stub!(:current_user).and_return(sender)
    
    sender.messages_from.should be_blank
    post :send_msg_to, :message => {:subject => "test subject", :body => ""}, :login => receiver.login
    sender.reload
    sender.messages_from.should be_blank
    response.should be_success
    response.should render_template "messages/send_msg_to"
    assigns[:message].subject.should == "test subject"
  end
  
  it "should create a new message when POST'ing a valid message to :send_msg_to" do
    sender = Factory.create :registered_guy
    receiver = Factory.create :registered_girl
    sender.stub!(:closest_relationship).and_return(:location)
    @controller.stub!(:current_user).and_return(sender)
    
    sender.messages_from.should be_blank
    post :send_msg_to, :message => {:subject => "test subject", :body => "test body"}, :login => receiver.login
    sender.reload
    sender.messages_from.length.should == 1
    sender.messages_from.first.subject.should == "test subject"
    sender.messages_from.first.body.should == "test body"
    response.should be_redirect
    flash[:notice].should == "Message sent to #{receiver.login}."
  end
  
  it "should import unregistered users into the DB and attach a message to them" do
    User.find_by_login("panavera").should be_blank
    sender = Factory.create :registered_girl
    @controller.stub!(:current_user).and_return(sender)
    
    sender.messages_from.should be_blank
    sender.stub(:get_twitter_user).and_return("id" => "4672185590",
                                              "screen_name" => "panavera",
                                              "profile_image_url" => "http://whatever")
    post :send_msg_to, :message => {:subject => "test subject", :body => "test body"}, :login => "panavera"
    sender.reload
    sender.messages_from.length.should == 1
    sender.messages_from.first.subject.should == "test subject"
    sender.messages_from.first.body.should == "test body"
    sender.messages_from.first.to_user.login.should == "panavera"
    response.should be_redirect
    flash[:notice].should == "Message sent to panavera."    
  end
  
  it "should render sent messages with a GET to :sent" do
    @controller.stub!(:current_user).and_return(Factory.create :registered_guy)
    get :sent, :id => 1
    response.should be_success
  end
  
  it "should show the Reply button when a recipient views a message sent to them" do
    message = Factory.create :message
    @controller.stub!(:current_user).and_return(message.to_user)
    message.from_user.like_and_notify(message.to_user)
    message.to_user.like_and_notify(message.from_user)
    get :show, :id => message.id
    response.should be_success
    response.should include_text("Reply")    
  end
  
  it "should not show the Reply button when a sender views their own message" do
    message = Factory.create :message
    @controller.stub!(:current_user).and_return(message.from_user)
    get :show, :id => message.id
    response.should be_success
    response.should_not include_text("Reply")
  end
  
  it "should send a tweet when the user is a registered user and no email address is entered" do
    sender = Factory.create :registered_guy
    receiver = Factory.create :registered_guy, :email => ""
    @controller.stub!(:current_user).and_return(sender)
    User.should_receive(:send_tweet)
    post :send_msg_to, :message => {:subject => "test subject", :body => "test body"}, :login => receiver.login
  end
  
  it "should send a tweet when the user is a non registered user" do
    sender = Factory.create :registered_guy
    receiver = Factory.create(:unregistered_user )
    @controller.stub!(:current_user).and_return(sender)
    User.should_receive(:send_tweet).twice
    post :send_msg_to, :message => {:subject => "test subject", :body => "test body"}, :login => receiver.login
  end

end
