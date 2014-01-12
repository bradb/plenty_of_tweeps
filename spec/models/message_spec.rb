require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "A Message" do
  
  before :each do
    @reged_guy = Factory.create :registered_guy
    @reged_girl = Factory.create :registered_girl
  end
  
  it "should set User#to_user to the recipient when sent" do
    message = @reged_guy.send_message_to_and_notify(@reged_girl, :subject => "hi", :body => "test")
    message.to_user.should == @reged_girl
  end

  it "should be unread when first created" do
    message = @reged_guy.send_message_to_and_notify(@reged_girl, :subject => "hi", :body => "test")
    message.unread?.should == true
  end

  it "should be able to be marked read" do
    message = @reged_guy.send_message_to_and_notify(@reged_girl, :subject => "hi", :body => "test")
    message.unread?.should == true
    message.mark_read!
    message.unread?.should == false
  end
  
  it "should always be included in all_messages_to_count, unread_messages_count when created" do
    @reged_girl.all_messages_to_count.should == 0
    @reged_girl.all_unread_messages_count == 0
    
    @reged_guy.send_message_to_and_notify(@reged_girl, :subject => "hi", :body => "test")
    
    @reged_girl.reload
    @reged_girl.all_messages_to_count.should == 1
    @reged_girl.all_unread_messages_count.should == 1
  end
  
  it "should be removed from unread_messages_count once read" do
    @reged_girl.all_unread_messages_count == 0    
    message = @reged_guy.send_message_to_and_notify(@reged_girl, :subject => "hi", :body => "test")
    @reged_girl.reload
    @reged_girl.all_unread_messages_count.should == 1
    message.mark_read!
    @reged_girl.all_unread_messages_count.should == 0
  end
  
  it "should become part of its non-paid-member recipient's visible_messages_to list " +
     "only if the sender is a mutual admirer" do
    
    @reged_girl.visible_messages_to.should be_blank
    @reged_girl.stub!(:paid_member?).and_return(false)

    message = @reged_guy.send_message_to_and_notify(@reged_girl, :subject => "hi", :body => "test")
    @reged_girl.reload
    @reged_girl.mutual_admirers.should be_blank

    @reged_girl.visible_messages_to.should be_blank
    
    @reged_guy.like_and_notify @reged_girl
    @reged_girl.like_and_notify @reged_guy
    @reged_girl.reload
    @reged_girl.mutual_admirers.should == [@reged_guy]
    
    @reged_girl.visible_messages_to.should == [message]
  end
  
  it "should become part of its recipient's visible_messages_to list if the recipient is a paid member" do
    @reged_girl.visible_messages_to.should be_blank
    
    message = @reged_guy.send_message_to_and_notify(@reged_girl, :subject => "hi", :body => "test")
    @reged_girl.reload
    @reged_girl.stub!(:paid_member?).and_return(false)
    @reged_girl.visible_messages_to.should be_blank
    
    @reged_girl.stub!(:paid_member?).and_return(true)
    @reged_girl.reload
    @reged_girl.visible_messages_to.should == [message]
  end
  
  # it "should NOT be included in all_messages_to or unread_messages when sender and recipient " +
  #    "are not mutual admirers, unless recipient is a paid member" do
  #   @reged_girl.all_messages_to.should be_blank
  #   @reged_girl.unread_messages.should be_blank
  #   
  #   message = @reged_guy.send_message_to_and_notify(@reged_girl, :subject => "hi", :body => "test")
  #   
  #   @reged_girl.reload
  #   @reged_girl.paid_member?.should == false
  #   @reged_girl.mutual_admirers.should be_blank
  # 
  #   @reged_girl.all_messages_to.should be_blank
  #   @reged_girl.unread_messages.should be_blank
  #   
  #   @reged_girl.extend_membership_to 1.week.from_now
  #   @reged_girl.reload
  #   
  #   @reged_girl.all_messages_to.should == [message]
  #   @reged_girl.unread_messages.should == [message]
  # end
  # 
  # it "should be included in all_messages_to and and unread_messages when send and recipient " +
  #    "are mutual admirers" do
  #   @reged_girl.all_messages_to.should be_blank
  #   @reged_girl.unread_messages.should be_blank
  #   
  #   message = @reged_guy.send_message_to_and_notify(@reged_girl, :subject => "hi", :body => "test")
  #   
  #   @reged_girl.reload
  #   @reged_girl.paid_member?.should == false
  #   @reged_girl.mutual_admirers.should be_blank
  # 
  #   @reged_girl.all_messages_to.should be_blank
  #   @reged_girl.unread_messages.should be_blank
  # 
  #   # Guy likes girl. She still can't see his messages.
  #   @reged_guy.like_and_notify @reged_girl
  #   @reged_girl.reload
  #   @reged_girl.mutual_admirers.should be_blank
  #   @reged_girl.all_messages_to.should be_blank
  #   @reged_girl.unread_messages.should be_blank
  # 
  #   # Girl likes guy and the floodgates of affection open.
  #   @reged_girl.like_and_notify @reged_guy
  #   @reged_girl.reload
  #   @reged_girl.mutual_admirers.should == [@reged_guy]
  #   @reged_girl.all_messages_to.should == [message]
  #   @reged_girl.unread_messages.should == [message]
  # end
    
end