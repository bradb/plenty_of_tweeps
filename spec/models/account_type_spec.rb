require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

Spec::Matchers.define :be_allowed_to_create do |plural_assoc_name, options|
  match do |user|
    options.assert_valid_keys(:maximum, :time_frame, :foreign_key, :message)
    time_frame = options[:time_frame]
    maximum = options[:maximum]
    foreign_key = options[:foreign_key] || :user_id
    factory_name = plural_assoc_name.to_s.singularize
    error_message = options[:message]
    
    created_objects = []
    maximum.times { created_objects << Factory(factory_name, foreign_key => user.id) }
    object_that_shouldnt_be_createable = Factory.build(factory_name, foreign_key => user.id)
    
    object_over_quota_invalid_with_expected_error_message = (
      object_that_shouldnt_be_createable.invalid? &&
      object_that_shouldnt_be_createable.errors.on_base == error_message)

    if time_frame && object_over_quota_invalid_with_expected_error_message
      created_objects.last.update_attributes(:created_at => (time_frame + 1.second).ago)
      object_that_shouldnt_be_createable.valid?
    else
      object_over_quota_invalid_with_expected_error_message
    end
  end
end

describe "Account type:" do
  
  context "Introvert" do

    before :each do
      @user = Factory(:registered_guy, :account_type => "I")
      @user.should be_introvert
    end
  
    it "should require paid_until to be nil" do
      @user.paid_until.should be_blank
      @user.should be_valid
      @user.paid_until = 1.month.from_now
      @user.should_not be_valid
      @user.errors.on(:paid_until).should == "must be blank"
    end
  
  
    it "should require months_remaining to be nil" do
      @user.months_remaining.should be_blank
      @user.should be_valid
      @user.months_remaining = 1.month.from_now
      @user.should_not be_valid
      @user.errors.on(:months_remaining).should == "must be blank"    
    end
    
    it "should allow a maximum of two photo uploads" do
      @user.photos.should be_empty
      assert_photo_upload_limit(2)
    end
  
    it "should allow a maximum of one sent message every 24 hours" do
      @user.messages_from.should be_empty
      assert_sent_messages_per_day_limit(1)
    end
  
    it "should allow a maximum of one liked profile per day" do
      @user.liked_users.should be_empty
      assert_liked_profiles_per_day_limit(1)
    end
  
    it "should allow a maximum of one smile per day" do
      @user.smiles_sent.should be_empty
      assert_smiles_per_day_limit(1)
    end
    
  end

  context "Connector" do

    before(:each) do
      @user = Factory(:registered_guy, :account_type => "C", :paid_until => 1.month.from_now, :months_remaining => 11)
    end
  
    it "should require paid_until to be present" do
      @user.should be_valid
      @user.paid_until = nil
      @user.should_not be_valid
      @user.errors.on(:paid_until).should == "can't be blank"
    end
  
    it "should require months_remaining to be present" do
      @user.should be_valid
      @user.months_remaining = nil
      @user.should_not be_valid
      @user.errors.on(:months_remaining).should == ["can't be blank", "is not a number"]
    end
  
    it "should require months_remaining to be >= 0" do
      @user.should be_valid
      @user.months_remaining = -1
      @user.should_not be_valid
      @user.errors.on(:months_remaining).should == "must be greater than or equal to 0"
    end
  
    it "should allow a maximum of four photo uploads" do
      @user.photos.should be_empty
      assert_photo_upload_limit(4)
    end
  
    it "should allow a maximum of five sent messages every 24 hours" do
      @user.messages_from.should be_empty
      assert_sent_messages_per_day_limit(5)
    end
  
    it "should allow a maximum of five liked profiles per day" do
      @user.liked_users.should be_empty
      assert_liked_profiles_per_day_limit(5)
    end
  
    it "should allow a maximum of five smiles per day" do
      @user.smiles_sent.should be_empty
      assert_smiles_per_day_limit(5)
    end

  end
  
  context "Social skydiver" do
    
    before(:each) do
      @user = Factory(:registered_guy, :account_type => "S", :paid_until => 1.month.from_now, :months_remaining => 11)
    end
  
    it "should require paid_until to be present" do
      @user.should be_valid
      @user.paid_until = nil
      @user.should_not be_valid
      @user.errors.on(:paid_until).should == "can't be blank"
    end
  
    it "should require months_remaining to be present" do
      @user.should be_valid
      @user.months_remaining = nil
      @user.should_not be_valid
      @user.errors.on(:months_remaining).should == ["can't be blank", "is not a number"]
    end
  
    it "should require months_remaining to be >= 0" do
      @user.should be_valid
      @user.months_remaining = -1
      @user.should_not be_valid
      @user.errors.on(:months_remaining).should == "must be greater than or equal to 0"
    end
  
    it "should allow a maximum of 10 photo uploads" do
      @user.photos.should be_empty
      assert_photo_upload_limit(10)
    end
  
    it "should allow a maximum of 12 sent messages every 24 hours" do
      @user.messages_from.should be_empty
      assert_sent_messages_per_day_limit(12)
    end
  
    it "should allow a maximum of 12 liked profiles per day" do
      @user.liked_users.should be_empty
      assert_liked_profiles_per_day_limit(12)
    end
  
    it "should allow a maximum of 12 smiles per day" do
      @user.smiles_sent.should be_empty
      assert_smiles_per_day_limit(12)
    end    
    
  end
  
  def assert_photo_upload_limit(maximum)
    @user.should be_allowed_to_create :photos, :maximum => maximum,
                                      :message => "photo upload limit exceeded (maximum #{maximum} allowed)" 
  end
  
  def assert_sent_messages_per_day_limit(maximum)
    @user.should be_allowed_to_create :messages, :maximum => maximum, :time_frame => 24.hours, :foreign_key => :from_user_id,
                                      :message => "message sending limit exceeded (maximum #{maximum} every 24 hours)"    
  end
  
  def assert_liked_profiles_per_day_limit(maximum)
    @user.should be_allowed_to_create :user_likes, :maximum => maximum, :time_frame => 24.hours, :foreign_key => :source_user_id,
                                      :message => "liked profile limit exceeded (maximum #{maximum} every 24 hours)"    
  end
  
  def assert_smiles_per_day_limit(maximum)
    @user.should be_allowed_to_create :smiles, :maximum => maximum, :time_frame => 1.day, :foreign_key => :source_user_id,
                                      :message => "smile sending limit exceeded (maximum #{maximum} every 24 hours)"
  end
  
end