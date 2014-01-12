require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "User pagination" do
  
  it "should show page links when there are three or more results pages" do
    paginated_results = MatchingUsersPaginated.new
    paginated_results.results_per_page = 20
    paginated_results.total_results_count = 40
    paginated_results.show_page_links?.should == false
    
    paginated_results.total_results_count = 60
    paginated_results.show_page_links?.should == true
  end

  it "should show the 'First' and 'Last' links when more than 8 pages away from both ends of the result set" do
    paginated_results = MatchingUsersPaginated.new
    paginated_results.results_per_page = 20
    paginated_results.total_results_count = 400
    paginated_results.page = 6
    paginated_results.show_first_link?.should == false
    paginated_results.show_last_link?.should == false

    paginated_results.page = 17
    paginated_results.show_first_link?.should == false
    paginated_results.show_last_link?.should == false

    paginated_results.page = 10
    paginated_results.show_first_link?.should == true
    paginated_results.show_last_link?.should == true
  end
  
  it "should link to all page numbers when there are 10 pages or fewer of results" do
    paginated_results = MatchingUsersPaginated.new
    paginated_results.results_per_page = 20
    paginated_results.total_results_count = 200
    paginated_results.page_numbers_to_link.should == (1..10).to_a
  end
  
  it "should link to the first two and last eight pages, when you're within the last 8 pages of a result set > 10" do
    paginated_results = MatchingUsersPaginated.new
    paginated_results.results_per_page = 20
    paginated_results.total_results_count = 400
    paginated_results.page = 14
    paginated_results.page_numbers_to_link.should == (1..2).to_a + [nil] + (13..20).to_a
  end
  
  it "should link to the first 8 and last 2 pages when you're in the first 8 pages of a result set > 10" do
    paginated_results = MatchingUsersPaginated.new
    paginated_results.results_per_page = 20
    paginated_results.total_results_count = 400
    paginated_results.page = 8
    paginated_results.page_numbers_to_link.should == (1..8).to_a + [nil] + (19..20).to_a
  end
  
  it "should link to the 4 previous and 5 next pages, when you're in the middle of a result set > 10" do
    paginated_results = MatchingUsersPaginated.new
    paginated_results.results_per_page = 20
    paginated_results.total_results_count = 400
    paginated_results.page = 11
    paginated_results.page_numbers_to_link.should == (7..10).to_a + [nil] + (12..16).to_a
  end
  
end