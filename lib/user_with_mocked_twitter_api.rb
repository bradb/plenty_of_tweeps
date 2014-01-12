require 'geokit'
require 'geokit-rails'
require 'app/models/user'

# Mock out Twitter API methods, to avoid slamming into the rate limiter.
# Toggle this by
class User

  def get_twitter_user(args)
  
  end

  def get_twitter_friends(args)

  end

  def get_twitter_followers(args)
  
  end

  def get_twitter_friend_ids
  end

  def get_twitter_follower_ids
  end

end