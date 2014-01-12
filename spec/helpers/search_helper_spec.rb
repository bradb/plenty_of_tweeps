require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SearchHelper do
  include SearchHelper
  
  it "should normalize city names into strings fit for URLs" do
    normalize_city_name_for_url("St. John's").should == "st-johns"
    normalize_city_name_for_url("New York").should == "new-york"
    normalize_city_name_for_url("New     York").should == "new-york"
    normalize_city_name_for_url(" New     York    ").should == "new-york"
  end

end
