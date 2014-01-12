# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

#SHOW ERROR PAGE.
config.action_controller.consider_all_requests_local = false

# Show full error reports and disable caching
#config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = true
ENV['CACHING'] = config.action_controller.perform_caching.to_s

config.cache_store = :enhanced_mem_cache_store

# Don't care if the mailer can't send
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

config.action_mailer.default_url_options = { :host => "localhost", :port => 3000 }
config.action_mailer.raise_delivery_errors = true
config.action_mailer.delivery_method = :smtp
config.action_mailer.perform_deliveries = false
