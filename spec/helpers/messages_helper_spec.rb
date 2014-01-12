require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MessagesHelper do
  include MessagesHelper

  it "should generate a reply subject line" do
    reply_subject("hi there").should == "Re: hi there"
    reply_subject("Re: hi there").should == "Re: hi there"
    reply_subject("Re:hi there").should == "Re:hi there"
    reply_subject("RE: hi there").should == "RE: hi there"
  end

end
