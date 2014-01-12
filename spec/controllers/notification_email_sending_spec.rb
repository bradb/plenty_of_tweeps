require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MessagesController, "A message being sent" do

  integrate_views
  
  before(:each) do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    fake_pot_human = Factory.create(:unregistered_user)
    User.stub!(:get_pot_human).and_return(fake_pot_human)
  end

  it "should email the target user telling them they've got a new message from someone" do
    sender = Factory.create :registered_guy
    receiver = Factory.create :registered_girl
    sender.stub!(:paid_member?).and_return(false)
    receiver.stub!(:paid_member?).and_return(false)
    @controller.stub!(:current_user).and_return(sender)
    User.stub!(:find_by_login).and_return(receiver)

    ActionMailer::Base.deliveries.should be_blank
    receiver.email_on_new_message?.should == true
    post :send_msg_to, :message => {:subject => "test subject", :body => "test body"}, :login => receiver.login
    response.should be_redirect
    ActionMailer::Base.deliveries.length.should == 1
    email_that_got_sent = ActionMailer::Base.deliveries.first
    email_that_got_sent.subject.should == "Someone sent you a message on Plenty of Tweeps"
    email_that_got_sent.body.should include_text "http://test.host/inbox"
  end  
  
  it "should email the target user telling them they've got a message from $username when " +
     "sender and receiver are mutual admirers" do
    sender = Factory.create :registered_guy
    receiver = Factory.create :registered_girl
    ActionMailer::Base.deliveries.should be_blank
    sender.like_and_notify(receiver)
    receiver.like_and_notify(sender)
    @controller.stub!(:current_user).and_return(sender)    

    ActionMailer::Base.deliveries.length.should == 2
    receiver.email_on_new_message?.should == true
    post :send_msg_to, :message => {:subject => "test subject", :body => "test body"}, :login => receiver.login
    response.should be_redirect
    ActionMailer::Base.deliveries.length.should == 3
    email_that_got_sent = ActionMailer::Base.deliveries.third
    email_that_got_sent.subject.should == "#{sender.login} sent you a message on Plenty of Tweeps"
    email_that_got_sent.body.should include_text "test subject"
    email_that_got_sent.body.should include_text "test body"
    email_that_got_sent.body.should include_text "/inbox/send_msg_to/#{sender.login}"
    email_that_got_sent.body.should include_text "http://test.host/inbox"
  end
  
  it "should email the target user telling them they've got a message from $username when " +
     "the sender is a paid member" do
    sender = Factory.create :registered_guy
    receiver = Factory.create :registered_girl
    sender.stub!(:paid_member?).and_return(true)
    @controller.stub!(:current_user).and_return(sender)    
    
    ActionMailer::Base.deliveries.should be_blank
    receiver.email_on_new_message?.should == true
    post :send_msg_to, :message => {:subject => "test subject", :body => "test body"}, :login => receiver.login
    response.should be_redirect
    ActionMailer::Base.deliveries.length.should == 1
    email_that_got_sent = ActionMailer::Base.deliveries.first
    email_that_got_sent.subject.should == "#{sender.login} sent you a message on Plenty of Tweeps"
    email_that_got_sent.body.should include_text "test subject"
    email_that_got_sent.body.should include_text "test body"
    email_that_got_sent.body.should include_text "/inbox/send_msg_to/#{sender.login}"
    email_that_got_sent.body.should include_text "http://test.host/inbox"    
  end
 
  it "should email the target user telling them they've got a message from $username when " +
     "the receiver is a paid member" do
    sender = Factory.create :registered_guy
    receiver = Factory.create :registered_girl
    sender.stub!(:paid_member?).and_return(false)
    receiver.stub!(:paid_member?).and_return(true)
    @controller.stub!(:current_user).and_return(sender)    
   
    ActionMailer::Base.deliveries.should be_blank
    receiver.email_on_new_message?.should == true
    post :send_msg_to, :message => {:subject => "test subject", :body => "test body"}, :login => receiver.login
    response.should be_redirect
    ActionMailer::Base.deliveries.length.should == 1
    email_that_got_sent = ActionMailer::Base.deliveries.first
    email_that_got_sent.subject.should == "#{sender.login} sent you a message on Plenty of Tweeps"
    email_that_got_sent.body.should include_text "test subject"
    email_that_got_sent.body.should include_text "test body"
    email_that_got_sent.body.should include_text "/inbox/send_msg_to/#{sender.login}"
    email_that_got_sent.body.should include_text "http://test.host/inbox"    
  end
  
  it "should not email the target user when their email_on_new_message is false" do
    sender = Factory.create :registered_guy
    receiver = Factory.create :registered_girl, :email_on_new_message => false
    sender.stub!(:paid_member?).and_return(false)
    receiver.stub!(:paid_member?).and_return(true)
    @controller.stub!(:current_user).and_return(sender)    
   
    ActionMailer::Base.deliveries.should be_blank
    receiver.email_on_new_message?.should == false
    post :send_msg_to, :message => {:subject => "test subject", :body => "test body"}, :login => receiver.login
    ActionMailer::Base.deliveries.should be_blank
  end

  it "should email the source user telling them one of the people they liked joined" do
    reged_guy = Factory.create :registered_guy
    reged_guy.email_on_new_message?.should == true
    unreged_girl = Factory.create :unregistered_user
    unreged_girl.save!
    reged_guy.like_and_notify(unreged_girl)
    unreged_girl.register_and_send_welcome_message! :min_age => "20",
                                                    :max_age => "35",
                                                    :email => "whatever@blah.com",
                                                    :"birth_date(3i)" => "19",
                                                    :"birth_date(2i)" => "11",
                                                    :"birth_date(1i)" => "1978",
                                                    :interested_in => "M",
                                                    :gender => "F"
    unreged_girl.notify_interested! 
    ActionMailer::Base.deliveries.length.should == 2
    reged_guy.email_on_new_message?.should == true
    
    sent_msgs = ActionMailer::Base.deliveries
    sent_msgs.first.subject.should == "#{User.get_pot_human.login} sent you a message on Plenty of Tweeps"
    sent_msgs.second.subject.should == "Someone you liked joined Plenty of Tweeps!"
  end

  it "should email the target user telling them they've been liked, " +
     "if the target user's email address exists in our system" do
    sender = Factory.create :registered_guy
    receiver = Factory.create :registered_girl
    ActionMailer::Base.deliveries.should be_blank
    sender.like_and_notify(receiver)
  
    ActionMailer::Base.deliveries.length.should == 1
    email_that_got_sent = ActionMailer::Base.deliveries[0]
    email_that_got_sent.subject.should == "Someone on Plenty of Tweeps likes your profile!"
  end
      
end