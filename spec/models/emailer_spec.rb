require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

include EmailSpec::Helpers
include EmailSpec::Matchers

describe "A smile notification email" do

  before(:all) do
    @source_user = Factory(:registered_guy, :login => "30sleeps", :email => "source_user@example.com")
    @target_user = Factory(:registered_girl, :login => "alicia_CHt", :email => "target_user@example.com")
    @email = Emailer.create_smile_notification(@source_user, @target_user, :location)
  end

  it "should be addressed to the target user's email address" do
    @email.should deliver_to("target_user@example.com")
  end

  it "should address the target user in the body of the email" do
    @email.should have_text(/Hi alicia_CHt/)
  end
  
  it "should say that someone sent them a smile" do
    @email.should have_text(/Someone on Plenty of Tweeps just sent you a smile!/)
  end

  it "should contain a link to activity page" do
    @email.should have_text(%r{http://.*/recent})
  end

  it "should have the correct subject" do
    @email.should have_subject(/Someone on Plenty of Tweeps sent you a smile!/)
  end
  
  after(:all) do
    @source_user.destroy
    @target_user.destroy
  end

end

describe "A smile recipient joined notification" do
  
  before(:all) do
    @smile_recipient = Factory(:registered_guy, :login => "30sleeps", :email => "smile_recip@example.com")
    @smile_sender = Factory(:registered_girl, :login => "alicia_CHt", :email => "smile_sender@example.com")
    @email = Emailer.create_smile_recipient_joined_notification(@smile_recipient, @smile_sender)
  end

  it "should be addressed to the smile sender's email address" do
    @email.should deliver_to("smile_sender@example.com")
  end

  it "should address the smile sender in the body of the email" do
    @email.should have_text(/Hi alicia_CHt/)
  end
  
  it "should say that someone they sent a smile to joined" do
    @email.should have_text(/Someone you sent a smile to.*joined/)
  end

  it "should contain a link to the smile recipient's profile" do
    @email.should have_text(%r{http://.*/users/30sleeps})
  end

  it "should have the correct subject" do
    @email.should have_subject(/Someone you smiled at joined Plenty of Tweeps!/)
  end
  
  after(:all) do
    @smile_recipient.destroy
    @smile_sender.destroy
  end
  
end

describe "A users nearby notification" do
  
  before(:all) do
    @reged_guy = Factory(:registered_guy, :min_age => 25, :max_age => 30)
    @m_27 = Factory(:registered_guy, :login => "male_27", :birth_date => 27.years.ago)
    @f_26 = Factory(:registered_girl, :login => "female_26", :birth_date => 26.years.ago)
    @f_29 = Factory(:registered_girl, :login => "female_29", :birth_date => 29.years.ago)
    @f_33 = Factory(:registered_girl, :login => "female_33", :birth_date => 33.years.ago)
  end
  
  it "should be addressed to the user being notified" do
    @email = Emailer.create_nearby_matches_notification(@reged_guy)
    @email.should deliver_to(@reged_guy.email)
  end
  
  it "should have the correct subject" do
    @email = Emailer.create_nearby_matches_notification(@reged_guy)
    @email.should have_subject(/Your latest matches on Plenty of Tweeps!/)
  end
  
  it "should show only the users matching the notified user's search criteria" do
    @email = Emailer.create_nearby_matches_notification(@reged_guy)
    @email.should have_text(/female_26/)
    @email.should have_text(/female_29/)
    @email.should_not have_text(/female_33/)
    @email.should_not have_text(/male_27/)
  end
  
  after(:all) do
    [@reged_guy, @f_26, @f_29, @f_33, @m_27].each { |u| u.destroy }
  end
  
end