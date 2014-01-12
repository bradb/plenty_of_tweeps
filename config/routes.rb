ActionController::Routing::Routes.draw do |map|
  map.resources :payment_notifications
  map.resources :messages, :as => "inbox", :collection => {:sent => :get}
  map.resources :users,
                :member => { :send_smile => :post, :like => :post, :invite => :post, :follow => :post, :unfollow => :post },
                :collection => { :welcome => :get, :setup => [:get, :post],
                                 :set_location => [:get, :post],
                                 :get_locations => [:get],
                                 :profile => [:get, :put],
                                 :who_i_like => :get,
                                 :who_likes_me => :get,
                                 :who_likes_me_all => :get, 
                                 :manage_photos => [:get, :post, :put, :delete],
                                 :upgrade_profile => [:get, :post],
                                 :forward_to_paypal => :get,
                                 :requestpage => :get,
                                 :random_profile => :get,
                                 :email_settings => [:get, :post],
                                 :screen_name_autocomplete_source => [:get],
                                 :upgrade_account => [:get] }
  map.resources :smiles

  map.with_options :controller => "actions" do |actions|
    actions.recent_activity 'recent', :action => "index"
    actions.close_someone_likes_me_box 'close_someone_likes_me_box', :action => "close_someone_likes_me_box"
    actions.someone_likes 'likes/:user', :action => "likes"
  end
  
  map.with_options :controller => "messages" do |messages|
    messages.send_msg_to 'inbox/send_msg_to/:login', :action => "send_msg_to"
    messages.show_sent_msg 'inbox/sent/:id', :action => "show"
  end

  map.with_options :controller => "search" do |search|
    search.search_nearby 'search/nearby', :action => "nearby"
    search.search_all_twitter_users_nearby 'search/all_twitter_users_nearby', :action => "all_twitter_users_nearby"
    search.city_search 'cities/:country_code/:city', :action => "all_twitter_users_nearby"
    search.search_image_gallery 'search/image_gallery', :action => "image_gallery"
    search.search_friends 'search/friends', :action => "friends"
    search.search_followers 'search/followers', :action => "followers"
    search.search_all_twitter_friends 'search/all_twitter_friends', :action => "all_twitter_friends"
    search.search_all_twitter_followers 'search/all_twitter_followers', :action => "all_twitter_followers"
    search.go_to_user 'search/go_to_user', :action => "go_to_user"
    search.cities 'cities', :action => "cities"
  end

  map.with_options :controller => "admin" do |admin|
    admin.import 'import', :action => "import_nearby"
    admin.import_user 'import_user/:twitter_username', :action => "import_nearby"
    admin.set_gender 'set_gender/:login/:gender/:index_on_page', :action => "set_gender"    
    admin.ignore 'ignore/:index_on_page', :action => "ignore"
  end
  
  map.with_options :controller => "welcome" do |welcome|
    welcome.root :action => "index"
    welcome.about 'about', :action => "about"
    welcome.contact_us 'contact_us', :action => "contact_us"
    welcome.thanks 'thanks', :action => "thanks"
    welcome.payment_cancelled 'payment_cancelled', :action => "payment_cancelled"
  end
  
  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  
  map.connect '*path', :controller => 'application', :action => 'rescue_404' unless ::ActionController::Base.consider_all_requests_local
end