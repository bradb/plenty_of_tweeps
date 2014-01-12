require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "search/_user_listing_pagination.html.erb" do
  
  it "should not render at all when there is only one results page" do
    one_results_page = MatchingUsersPaginated.new
    one_results_page.results_per_page = 20
    one_results_page.total_results_count = 5
    render :partial => "search/user_listing_pagination", :locals => {:matching_users_paginated => one_results_page}
    should_not_show "#pagination"
  end
  
  it "should render when there is more than one results page" do
    two_results_pages = MatchingUsersPaginated.new
    two_results_pages.results_per_page = 20
    two_results_pages.total_results_count = 40
    render :partial => "search/user_listing_pagination", :locals => {:matching_users_paginated => two_results_pages}
    should_show "#pagination"
  end
  
  it "should render only a 'Next >>' link when on the first results page" do
    first_page_results = MatchingUsersPaginated.new
    first_page_results.results_per_page = 20
    first_page_results.total_results_count = 40
    first_page_results.page = 1
    render :partial => "search/user_listing_pagination", :locals => {:matching_users_paginated => first_page_results}
    should_not_show "#prev"
    should_not_show "#page-links"
    should_show "#next"
  end
   
  it "should render only a '<< Previous' link when on the last results page" do
    last_page_results = MatchingUsersPaginated.new
    last_page_results.results_per_page = 20
    last_page_results.total_results_count = 40
    last_page_results.page = 2
    render :partial => "search/user_listing_pagination", :locals => {:matching_users_paginated => last_page_results}
    should_show "#prev"
    should_not_show "#page-links"
    should_not_show "#next"
  end

  it "should render individual page links when there are more than three result pages (ex. with 5 result pages)" do
    five_results_pages = MatchingUsersPaginated.new
    five_results_pages.results_per_page = 2
    five_results_pages.total_results_count = 9
    five_results_pages.page = 2
    render :partial => "search/user_listing_pagination", :locals => {:matching_users_paginated => five_results_pages}
    should_show "#prev"
    should_show "#next"
    should_show "#page-links"
    should_not_show "#page-#{five_results_pages.page}-link"
    (1..5).each do |page_num|
      next if page_num == five_results_pages.page
      should_show "#page-#{page_num}-link"
    end
  end
  
  it "should render a link for all 10 pages when there are 10 result pages" do
    ten_results_pages = MatchingUsersPaginated.new
    ten_results_pages.results_per_page = 2
    ten_results_pages.total_results_count = 20
    ten_results_pages.page = 6
    render :partial => "search/user_listing_pagination", :locals => {:matching_users_paginated => ten_results_pages}
    should_show "#prev"
    should_show "#next"
    should_show "#page-links"
    should_not_show "#page-#{ten_results_pages.page}-link"
    (1..10).each do |page_num|
      next if page_num == ten_results_pages.page
      should_show "#page-#{page_num}-link"
    end    
  end

  it "should render links for the first two and last eight pages, when you're within the last 8 pages of a result set > 10" do
    eleven_results_pages = MatchingUsersPaginated.new
    eleven_results_pages.results_per_page = 2
    eleven_results_pages.total_results_count = 40
    eleven_results_pages.page = 15
    render :partial => "search/user_listing_pagination", :locals => {:matching_users_paginated => eleven_results_pages}
    should_show "#prev"
    should_show "#next"
    should_show "#page-links"
    should_show "#page-links-elision"
    should_not_show "#page-#{eleven_results_pages.page}-link"
    ((1..2).to_a + (13..20).to_a).each do |page_num|
      next if page_num == eleven_results_pages.page
      should_show "#page-#{page_num}-link"
    end
  end
  
  it "should render links for the first 8 and last 2 pages when you're in the first 8 pages of a result set > 10" do
    fifteen_results_pages = MatchingUsersPaginated.new
    fifteen_results_pages.results_per_page = 20
    fifteen_results_pages.total_results_count = 402
    fifteen_results_pages.page = 8
    render :partial => "search/user_listing_pagination", :locals => {:matching_users_paginated => fifteen_results_pages}
    should_show "#prev"
    should_show "#next"
    should_show "#page-links"
    should_show "#page-links-elision"
    should_not_show "#page-#{fifteen_results_pages.page}-link"
    ((1..8).to_a + (20..21).to_a).each do |page_num|
      next if page_num == fifteen_results_pages.page
      should_show "#page-#{page_num}-link"
    end    
  end
  
  it "should render links for the 4 previous and 5 next pages, and 'First'/'Last' links when you're in the middle of a result set > 10" do
    fifteen_results_pages = MatchingUsersPaginated.new
    fifteen_results_pages.results_per_page = 20
    fifteen_results_pages.total_results_count = 402
    fifteen_results_pages.page = 9
    render :partial => "search/user_listing_pagination", :locals => {:matching_users_paginated => fifteen_results_pages}
    should_show "#prev"
    should_show "#next"
    should_show "#first"
    should_show "#last"
    should_show "#page-links"
    should_show "#page-links-elision"
    should_not_show "#page-#{fifteen_results_pages.page}-link"
    ((5..8).to_a + (10..14).to_a).each do |page_num|
      next if page_num == fifteen_results_pages.page
      should_show "#page-#{page_num}-link"
    end
  end

  protected

  def should_show(tag)
    response.should have_tag tag
  end
  
  def should_not_show(tag)
    response.should_not have_tag tag
  end
  
end