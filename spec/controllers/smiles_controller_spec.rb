require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SmilesController do

  context "DELETE to :destroy" do
  
    it "should soft delete the smile" do
      reged_guy = Factory(:registered_guy)
      reged_girl = Factory(:registered_girl)
      controller.stub(:current_user).and_return(reged_guy)
      
      reged_girl.send_smile_and_notify(reged_guy)
    
      proc { delete :destroy, :id => reged_girl.smiles_sent.first.id }.should change(Smile, :count).by(-1)
    end
  
  end

end