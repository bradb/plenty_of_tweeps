require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "An action" do
  include ActionController::TestProcess
  
  it "should be created when one user likes another" do
    Action.all.should be_blank
    reged_guy = Factory(:registered_guy)
    reged_girl = Factory(:registered_girl)
    reged_guy.like_and_notify(reged_girl)
    actions = Action.all
    actions.length.should == 1
    actions.first.item.should be_instance_of UserLike
    actions.first.item.source_user.should == reged_guy
    actions.first.item.target_user.should == reged_girl
  end
  
  it "should not be created when an invalid photo is uploaded" do
    reged_guy = Factory(:registered_guy)

    Action.all.should be_blank
    photo = Photo.new :data => fixture_file_upload('files/test.jpg', 'image/jpeg', :binary)
    photo.stub!(:save_attached_files).and_return true
    photo.save.should be_false
    Action.all.should be_blank
  end

  it "should be created when a photo is created" do
    reged_guy = Factory(:registered_guy)

    Action.all.should be_blank
    photo = Photo.new :data => fixture_file_upload('files/test.jpg', 'image/jpeg', :binary),
                      :user_id => reged_guy.id
    photo.stub!(:save_attached_files).and_return true
    photo.save.should be_true
    actions = Action.all
    actions.length.should == 1
    actions.first.item.should be_an_instance_of Photo
    actions.first.item.user.should == reged_guy
  end
  
  # it "should be created when a user registers" do
  # end
  
end