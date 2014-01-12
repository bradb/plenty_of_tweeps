require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "The Manage Photo page" do
  include ActionController::TestProcess

  it 'should allow JPG images' do
    photo = Photo.new :data => fixture_file_upload('files/test.jpg', 'image/jpeg', :binary),
                      :user_id => Factory.create(:registered_guy).id
    photo.stub!(:save_attached_files).and_return true
    photo.save.should be_true
  end

  it 'should allow PNG images' do
    photo = Photo.new :data => fixture_file_upload('files/logo.png', 'image/png', :binary),
                      :user_id => Factory.create(:registered_guy).id
    photo.stub!(:save_attached_files).and_return true
    photo.save.should be_true
  end
end