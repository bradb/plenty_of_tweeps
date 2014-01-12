require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UsersHelper do
  
  include UsersHelper

  describe "#profile_upgrade_account_box_text" do
    
    before(:each) do
      @user = Factory(:registered_guy)
      @user.daily_smile_limit_reached?.should == false
      @user.daily_message_limit_reached?.should == false
      @user.daily_like_profile_limit_reached?.should == false
    end
    
    it "should return nil when a user is below their limits for all of " +
       "sending smiles, messages, and liking profiles" do
      profile_upgrade_account_box_text(@user).should == nil
    end
    
    it "should return a string when a user reaches their daily limit for sending smiles" do
      @user.stub(:daily_smile_limit_reached?).and_return(true)
      profile_upgrade_account_box_text(@user).should == "sending smiles"
    end
    
    it "should return a string when a user reaches their daily limit for sending messages" do
      @user.stub(:daily_message_limit_reached?).and_return(true)
      profile_upgrade_account_box_text(@user).should == "sending messages"
    end
    
    it "should return a string when a user reaches their daily limit for liking profiles" do
      @user.stub(:daily_like_profile_limit_reached?).and_return(true)
      profile_upgrade_account_box_text(@user).should == "liking profiles"
    end
    
    it "should concatenate the limits reached when there are more than one" do
      @user.stub(:daily_smile_limit_reached?).and_return(true)
      @user.stub(:daily_message_limit_reached?).and_return(true)
      
      profile_upgrade_account_box_text(@user).should == "sending smiles and sending messages"

      @user.stub(:daily_like_profile_limit_reached?).and_return(true)
      profile_upgrade_account_box_text(@user).should == "sending smiles, sending messages, and liking profiles"
    end
        
  end
  
end
