# Settings specified here will take precedence over those in config/environment.rb

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = true
config.action_view.cache_template_loading            = true

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test
config.action_mailer.default_url_options = {:host => "test.host"}

# Use SQL instead of Active Record's schema dumper when creating the test database.
# This is necessary if your schema can't be completely dumped by the schema dumper,
# like if you have constraints or database-specific column types
# config.active_record.schema_format = :sql

TWITTER_AUTH_USER_HASH = {
  "profile_sidebar_border_color"=>"BDDCAD",
  "name"=>"Dale Carnegie ",
  "profile_sidebar_fill_color"=>"DDFFCC",
  "profile_background_tile"=>false,
  "profile_image_url"=>"http://a3.twimg.com/profile_images/236903911/DCT_logo_diamond_normal_normal.jpg",
  "location"=>"U.S. and 75+ countries",
  "created_at"=>"Fri Jul 25 12:46:09 +0000 2008",
  "profile_link_color"=>"0084B4",
  "favourites_count"=>5,
  "url"=>"http://www.dalecarnegie.com",
  "utc_offset"=>-18000,
  "id"=>15597251,
  "followers_count"=>2800,
  "protected"=>false,
  "profile_text_color"=>"333333",
  "notifications"=>false,
  "time_zone"=>"Eastern Time (US & Canada)",
  "verified"=>false,
  "profile_background_color"=>"9AE4E8",
  "description"=>"Dale Carnegie Training – The Leader In Workplace Learning and Development",
  "friends_count"=>2572,
  "statuses_count"=>468,
  "profile_background_image_url"=>"http://a3.twimg.com/profile_background_images/3512265/twitter_bkgd.gif",
  "status"=>{"created_at"=>"Sun Sep 20 14:30:20 +0000 2009",
  "favorited"=>false,
  "truncated"=>false,
  "text"=>"\"You are never defeated as long as you don't think the job is impossible\" -- @DaleCarnegie",
  "id"=>4124221105,
  "in_reply_to_user_id"=>nil,
  "in_reply_to_screen_name"=>nil,
  "source"=>"web",
  "in_reply_to_status_id"=>nil}, "following"=>true, "screen_name"=>"DaleCarnegie"}