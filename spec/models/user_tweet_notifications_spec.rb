require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "User tweet notifications" do

  it "should send a tweet to a registered user when they are liked" do
    reged_guy = Factory.create :registered_guy
    reged_girl = Factory.create :registered_girl, :email => ""
    User.should_receive(:send_tweet).with(/likes you/)
    reged_guy.like_and_notify reged_girl
  end
  
  it "should send two tweets the first time an unregistered user is liked - a notification and an apology - then no more after that" do
    reged_guy_1 = Factory.create :registered_guy
    reged_guy_2 = Factory.create :registered_guy
    unreged_girl = Factory.create :unregistered_user
    
    User.should_receive(:send_tweet).once.with(%r{likes you.*http://.*/likes/.*})
    User.should_receive(:send_tweet).once.with(/sorry for bothering you/)
    reged_guy_1.like_and_notify unreged_girl
    
    User.should_not_receive(:send_tweet)
    reged_guy_2.like_and_notify unreged_girl
  end
  
  it "should send two tweets the first time an unregistered user gets a message - a notification " +
     "and an apology - then no more after that" do
    reged_guy_1 = Factory.create :registered_guy
    reged_guy_2 = Factory.create :registered_guy
    unreged_girl = Factory.create :unregistered_user
    
    User.should_receive(:send_tweet).once.with(/sent you a message/)
    User.should_receive(:send_tweet).once.with(/sorry for bothering you/)
    reged_guy_1.send_message_to_and_notify(unreged_girl, :body => "test body", :subject => "test subject")
    
    User.should_not_receive(:send_tweet)
    reged_guy_2.send_message_to_and_notify(unreged_girl, :body => "test body", :subject => "test subject")
  end
  
  it "should not send any tweets to an unregistered user who gets a message, if they've already " +
     "been liked" do
    reged_guy_1 = Factory.create :registered_guy
    reged_guy_2 = Factory.create :registered_guy
    unreged_girl = Factory.create :unregistered_user
    
    User.should_receive(:send_tweet).once.with(/likes you/)
    User.should_receive(:send_tweet).once.with(/sorry for bothering you/)
    reged_guy_1.like_and_notify unreged_girl
    
    User.should_not_receive(:send_tweet)
    reged_guy_2.send_message_to_and_notify(unreged_girl, :body => "test body", :subject => "test subject")
  end
  
  it "should not send any tweets to an unregistered user who gets liked, if they've already been " +
     "sent a message" do
    reged_guy_1 = Factory.create :registered_guy
    reged_guy_2 = Factory.create :registered_guy
    unreged_girl = Factory.create :unregistered_user
    
    User.should_receive(:send_tweet).once.with(/sent you a message/)
    User.should_receive(:send_tweet).once.with(/sorry for bothering you/)
    reged_guy_1.send_message_to_and_notify(unreged_girl, :body => "test body", :subject => "test subject")
    
    User.should_not_receive(:send_tweet)
    reged_guy_2.like_and_notify unreged_girl
  end
  
end
