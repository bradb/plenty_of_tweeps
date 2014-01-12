def earliest_birth_date(age)
  age.to_i.years.ago.to_date - 1.year + 1.day
end

def latest_birth_date(age)
  age.to_i.years.ago.to_date + 1
end

def get_nearby_search_conditions(user, options)
  search_params = {}
  [:interested_in, :gender, :min_age, :max_age].each do |param|
    if options[param].present?
      search_params[param] = options[param]
    else
      search_params[param] = user.send(param)
    end
  end
  
  conditions = [
    "gender = ? AND " +
    "interested_in = ? AND " +
    "birth_date >= ? AND birth_date < ?",
    search_params[:interested_in],
    search_params[:gender],
    earliest_birth_date(search_params[:max_age]),
    latest_birth_date(search_params[:min_age])]
  
  return conditions
end

class User < TwitterAuth::GenericUser
  include ActionController::UrlWriter

  attr_accessor :latest_tweet

  # Paperclip
  has_many :photos, :dependent => :destroy

  def photo_attributes=(photo_attributes)
    photo_attributes.each do |attributes|
      photos.build(attributes)
    end
  end

  acts_as_mappable
  
  MIN_AGE_DEFAULT = 20
  MAX_AGE_DEFAULT = 35
  
  delegate :can_see_sent_messages_read?, :can_see_who_has_viewed_their_profile?, :to => :account_type_obj

  validate :must_be_18_or_older, :if => :registered?
  validates_presence_of :paid_until, :months_remaining, :if => :paid_account?
  validates_blankness_of :paid_until, :months_remaining, :unless => :paid_account?
  validates_numericality_of :months_remaining, :greater_than_or_equal_to => 0, :if => :paid_account?
  validates_presence_of :twitter_id
  validates_uniqueness_of :twitter_id, :on => :create, :message => "already taken"
  validates_uniqueness_of :email, :on => :save, :message => "already taken", :allow_blank => true
  validates_presence_of :gender, :interested_in, :birth_date, :min_age, :max_age,
                        :on => :save, :if => :registered?, :message => "required"
  validates_length_of :extended_bio, :maximum => 5000, :allow_nil => true, :on => :create, :message => "must be no longer than 5,000 characters"
  validates_format_of :email,
                      :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i,
                      :if => :registered?, 
                      :allow_blank => true
  validates_inclusion_of :account_type, :in => %w(I C S)

  has_many :messages_to, :class_name => "Message", :foreign_key => "to_user_id"
  has_many :messages_from_mutual_admirers, :class_name => "Message", :foreign_key => "to_user_id",
           :conditions => "from_user_id IN (SELECT u.id from users u, user_likes u1, user_likes u2 where u.id = u1.source_user_id AND u1.target_user_id = \#{id} AND u.id = u2.target_user_id AND u2.source_user_id = \#{id})" 
  has_many :messages_from, :class_name => "Message", :foreign_key => "from_user_id", :extend => InLast24HoursExtension

  has_many :unread_messages, :class_name => "Message", :foreign_key => "to_user_id",
           :conditions => {:unread => true}

  has_one :action, :as => :item, :dependent => :destroy
  has_many :user_likes, :class_name => "UserLike", :foreign_key => "source_user_id", :dependent => :destroy,
           :extend => InLast24HoursExtension
  has_many :user_liked_by, :class_name => "UserLike", :foreign_key => "target_user_id", :dependent => :destroy

  has_many :user_liked_by_and_likes, :class_name => "UserLike",
                                     :foreign_key => "target_user_id",
                                     :conditions => "source_user_id IN (SELECT target_user_id FROM user_likes WHERE source_user_id = \#{id})"

  has_many :liked_users, :through => :user_likes, :source => :target_user
  has_many :liked_by_users, :through => :user_liked_by, :source => :source_user
  has_many :mutual_admirers, :through => :user_liked_by_and_likes, :source => :source_user
  
  has_many :smiles_sent, :class_name => "Smile", :foreign_key => "source_user_id", :dependent => :destroy,
           :extend => InLast24HoursExtension
  has_many :smiles_received, :class_name => "Smile", :foreign_key => "target_user_id", :dependent => :destroy
  has_many :smiled_at_users, :through => :smiles_sent, :source => :target_user
  has_many :smiled_at_by_users, :through => :smiles_received, :source => :source_user
  has_many :profile_views, :foreign_key => "seen_user_id"
  has_many :profile_viewed_by_users, :through => :profile_views, :source => :viewed_by_user do
    def last_10_unique
      find(:all, :select => "MAX(profile_views.id) as pvid, users.*", :group => "users.id", :order => "pvid DESC", :limit => 10)
    end
  end

  def self.find_newest(options = {})
    options[:limit] ||= 27
    # find(:all, :conditions => "joined_on IS NOT NULL", :order => "joined_on DESC", :limit => options[:limit])
    find_by_sql(%q{(SELECT * FROM users WHERE joined_on IS NOT NULL AND gender = 'M')
                   UNION
                   (SELECT * FROM users WHERE joined_on IS NOT NULL AND gender = 'F')
                   ORDER BY RAND() LIMIT %d} % options[:limit])
  end

  def self.find_featured(user = nil)
    if user.present?
      find(:first, :conditions => ["gender = ? AND interested_in = ? AND id IN (SELECT user_id FROM photos GROUP BY user_id HAVING count(user_id) > 1) AND description IS NOT NULL AND description != ''", user.interested_in, user.gender], :order => "RAND()")
    else
      find(:first, :conditions => "id IN (SELECT user_id FROM photos GROUP BY user_id HAVING count(user_id) > 1) AND description IS NOT NULL AND description != ''", :order => "RAND()")
    end
  end
  
  def self.find_by_login_or_import_from_twitter(login, user_making_twitter_request)
    user = find_by_login(login)
    return user if user.present?

    twitter_auth_user_hash = user_making_twitter_request.get_twitter_user(login)
    return unless twitter_auth_user_hash.present?

    new_user = new_from_twitter_auth_user_hash(twitter_auth_user_hash)
    new_user.save!
    return new_user    
  end
  
  def self.get_pot_bot
    User.find_by_twitter_id(Constants::POT_BOT_ID)
  end
  
  def self.get_pot_human
    User.find_by_twitter_id(Constants::POT_HUMAN_ID)
  end

  def self.send_tweet(message)
    if RAILS_ENV == 'production'
      get_pot_bot.twitter.post('/statuses/update.json', 'status' => message)
    end
  
    if RAILS_ENV == 'development'
      puts "@PlentyOfTwps tweeted: #{message}"
    end
  end

  def self.new_from_twitter_auth_user_hash(twitter_auth_user_hash)
    u = User.new(twitter_auth_user_hash.slice("location", "description"))
    u.login = twitter_auth_user_hash["screen_name"]
    u.friends_count = twitter_auth_user_hash["friends_count"]
    u.followers_count = twitter_auth_user_hash["followers_count"]
    u.twitter_id = twitter_auth_user_hash["id"]
    u.url = twitter_auth_user_hash["url"]
    u.profile_image_url = twitter_auth_user_hash["profile_image_url"]
    u
  end

  def self.new_from_twitter_auth_tweet_hash(twitter_auth_tweet_hash)
    u = User.new
    u.location = twitter_auth_tweet_hash["location"]
    u.login = twitter_auth_tweet_hash["from_user"]
    u.twitter_id = twitter_auth_tweet_hash["from_user_id"]
    u.profile_image_url = twitter_auth_tweet_hash["profile_image_url"]
    u.latest_tweet = twitter_auth_tweet_hash["text"]
    u
  end
  
  def self.find_users_that_might_like(user)
    return [] unless user.liked_by_users.present?
    
    most_recent_liked_by_user = user.liked_by_users.first
    other_random_users = User.find_by_sql(["SELECT DISTINCT id, login, profile_image_url " +
                                           "FROM users " +
                                           "WHERE (gender = ? AND interested_in = ? AND id != ?) " +
                                           "ORDER BY RAND() " +
                                           "LIMIT 15",
                                           most_recent_liked_by_user.gender,
                                           most_recent_liked_by_user.interested_in,
                                           most_recent_liked_by_user.id])
    other_random_users << most_recent_liked_by_user
    other_random_users.shuffle
  end

    
  def profile_image_url
    piu = read_attribute(:profile_image_url)
    if piu.present?
      return piu.sub(/_normal\./, "_bigger.")
    else
      return ""
    end
  end

  def profile_image_url_fullsize
    piu = read_attribute(:profile_image_url)
    if piu.present?
      return piu.sub(/_normal\./, ".")
    else
      return ""
    end
  end
  
  # This is an instance, rather than class method, because it depends
  # on the current user's twitter session.
  def get_user_from_twitter_as_hash(screen_name_or_twitter_id)
    Rails.cache.fetch("/users/show/#{screen_name_or_twitter_id}", :expires_in => 2.hours) { twitter.get("/users/show/#{screen_name_or_twitter_id}") }
  end
  
  def profile_complete?
    description.present? && photos.present?
  end
  
  def paid_account?
    connector? || social_skydiver?
  end
                        
  def to_param
    login
  end
  
  def register_and_send_welcome_message!(options)
    self.attributes = options.slice :min_age, :max_age, :email, :"birth_date(3i)",
                                    :"birth_date(2i)", :"birth_date(1i)",
                                    :interested_in, :gender
    self.joined_on = Time.now
    save!
    
    action = Action.new
    action.item_id = self.id
    action.item_type = self.class.name
    action.save!
    
    welcome_message = Emailer.create_welcome_message(self)
    User.get_pot_human.send_message_to_and_notify(
        self, :subject => welcome_message.subject, :body => welcome_message.body)
  end
  
  def notify_interested!
    liked_by_users.each do | liked_by_user |
      Emailer.deliver_liked_user_joined_notification(self, liked_by_user)
    end
    
    smiled_at_by_users.each do | smiled_at_by_user |
      Emailer.deliver_smile_recipient_joined_notification(self, smiled_at_by_user)
    end
  end
  
  def registered?
    joined_on.present?
  end
  
  def unregistered?
    !registered?
  end
  
  def has_sent_an_unseen_smile_to?(target_user)
    smiles_sent.find_by_target_user_id(target_user.id).present?
  end
  
  def number_of_smiles_sent_to(target_user)
    Smile.send(:with_exclusive_scope) { smiles_sent.count(:conditions => {:target_user_id => target_user.id}) }
  end

  def like_and_notify(target_user)
    case target_user
    when User
      liked_user = like_user(target_user.login)
    when String
      liked_user = like_user(target_user)
    end
    
    send_notification_via_twitter_or_email(:like, liked_user) if liked_user
  end

  def send_smile_and_notify(target_user)
    case target_user
    when User
      smiled_at_user = send_smile_to_user(target_user.login)
    when String
      smiled_at_user = send_smile_to_user(target_user)
    end
    
    send_notification_via_twitter_or_email(:smile, smiled_at_user) if smiled_at_user
  end
  
  def likes?(target_user)
    case target_user
    when User
      return liked_users.any? { | liked_user | liked_user.login == target_user.login  }
    when String
      return liked_users.any? { | liked_user | liked_user.login == target_user }
    end
  end
  
  def age
    return nil unless birth_date.present?

    now = Time.now.utc.to_date
    now.year - birth_date.year - (birth_date.to_date.change(:year => now.year) > now ? 1 : 0)
  end
  
  def interested_in_display
    if interested_in == "M"
      return "guys"
    elsif interested_in == "F"
      return "girls"
    end
  end
  
  def interested_in_formal_display
    if interested_in == "M"
      return "men"
    elsif interested_in == "F"
      return "women"
    end
  end
  
  def gender_display
    return "" unless gender.present?

    if gender == "M"
      return "male"
    else
      return "female"
    end
  end
  
  def his_or_her
    return "" unless gender.present?

    if gender == "M"
      return "his"
    elsif gender == "F"
      return "her"
    else
      return ""
    end
  end
  
  def country_display
    country_code.present? ? Constants::COUNTRIES[country_code] : ""
  end
  
  def find_nearby(options)
    self.class.find :all,
                    :conditions => get_nearby_search_conditions(self, options),
                    :origin => [lat, lng], :within => 1000,
                    :order => options[:order] || "distance asc",
                    :limit => options[:limit]
  end
  
  def paginate_find_nearby(options = {})
    options = {} if options.blank?
    options[:results_per_page] ||= DEFAULT_SEARCH_RESULTS_PER_PAGE
    options[:page] ||= 1
    MatchingUsersPaginator.find :conditions => get_nearby_search_conditions(self, options),
                                :origin => [lat, lng], :within => 1000,
                                :results_per_page => options[:results_per_page],
                                :page => options[:page],
                                :order => "distance asc"
  end
  
  def paginate_import_nearby_twitter_users(options = {})
    options = {} if options.blank?
    page = options[:page] || 1
    matching_users_paginated = MatchingUsersPaginated.new
    matching_users_paginated.page = page.to_i
    matching_users_paginated.total_results_count=1500
    options[:results_per_page] ||= DEFAULT_SEARCH_RESULTS_PER_PAGE
    options[:page] ||= 1
    options[:radius] ||= 15
    if options[:twitter_username]
      matching_users_paginated.total_results_count=1
      options[:results_per_page] ||= 1
      twitter_hash = get_user_from_twitter_as_hash(options[:twitter_username])
      matching_users_paginated.current_page_results =  [User.new_from_twitter_auth_user_hash(twitter_hash)]
    else
      tweets_as_array_of_hashes = get_tweets_by_location_anon(options) || []
      matching_users_paginated.current_page_results = tweets_as_array_of_hashes["results"].map do | tweet_hash |
        if !User.find_by_login(tweet_hash["from_user"])
          User.new_from_twitter_auth_tweet_hash(tweet_hash)
        end
      end
    end
    
    matching_users_paginated

  end
  
  def paginate_all_twitter_users_nearby(options = {})
    options = {} if options.blank?
    page = options[:page] || 1
    matching_users_paginated = MatchingUsersPaginated.new
    matching_users_paginated.page = page.to_i
    matching_users_paginated.total_results_count = 1500
    options[:results_per_page] ||= DEFAULT_SEARCH_RESULTS_PER_PAGE
    options[:page] ||= 1
    options[:radius] ||= 50

    tweets_as_array_of_hashes = begin
      nearby_tweeters = get_nearby_tweeters(options)
      unique_nearby_tweeters = []
      seen_twitter_ids = {}
      nearby_tweeters["results"].each do | nearby_tweeter |
        next if seen_twitter_ids[nearby_tweeter["from_user_id"]]
        unique_nearby_tweeters << nearby_tweeter
        seen_twitter_ids[nearby_tweeter["from_user_id"]] = true
      end
      unique_nearby_tweeters
    end
    
    matching_users_paginated.current_page_results = tweets_as_array_of_hashes.map do | tweet_hash |
      User.new_from_twitter_auth_tweet_hash(tweet_hash)
    end

    matching_users_paginated
  end

  def get_nearby_tweeters(options = {})
    search_path = "http://search.twitter.com/search.json?geocode=#{options[:lat]},#{options[:lng]},#{options[:radius]}km&rpp=100&page=#{options[:page]}"
    Rails.cache.fetch(search_path, :expires_in => 3.minutes) { twitter.get(search_path) }
  end

  def paginate_all_friends(options = {})
    page = options[:page] || 1
    matching_users_paginated = MatchingUsersPaginated.new
    matching_users_paginated.page = page.to_i
    matching_users_paginated.results_per_page = DEFAULT_SEARCH_RESULTS_PER_PAGE
    matching_users_paginated.total_results_count = friends_count
    
    twitter_friends_as_array_of_hashes = get_twitter_friends || []
    matching_users_paginated.current_page_results = twitter_friends_as_array_of_hashes.map do | user_hash |
      User.new_from_twitter_auth_user_hash(user_hash)
    end
    matching_users_paginated
  end
  
  def paginate_only_reged_friends(options = {})
    page = options[:page] || 1
    matching_users_paginated = MatchingUsersPaginated.new
    matching_users_paginated.page = page.to_i
    matching_users_paginated.results_per_page = DEFAULT_SEARCH_RESULTS_PER_PAGE

    first_5k_friend_ids = get_twitter_friend_ids
    results = MatchingUsersPaginator.find :conditions => ["twitter_id IN (?) AND gender = ? AND interested_in = ?",
                                                          first_5k_friend_ids, interested_in, gender],
                                          :results_per_page => matching_users_paginated.results_per_page,
                                          :page => page
  end
  
  def count_only_reged_friends
    User.count :conditions => ["twitter_id IN (?) AND gender = ? AND interested_in = ?",
                               get_twitter_friend_ids, interested_in, gender]
  end
  
  def count_only_reged_followers
    User.count :conditions => ["twitter_id IN (?) AND gender = ? AND interested_in = ?",
                               get_twitter_follower_ids, interested_in, gender]
  end
  
  def paginate_all_followers(options = {})
    page = options[:page] || 1
    matching_users_paginated = MatchingUsersPaginated.new
    matching_users_paginated.page = page.to_i
    matching_users_paginated.results_per_page = DEFAULT_SEARCH_RESULTS_PER_PAGE
    matching_users_paginated.total_results_count = followers_count
    
    twitter_followers_as_array_of_hashes = get_twitter_followers(:page => page) || []
    matching_users_paginated.current_page_results = twitter_followers_as_array_of_hashes.map do | user_hash |
      User.new_from_twitter_auth_user_hash(user_hash)
    end
    matching_users_paginated    
  end

  def paginate_only_reged_followers(options = {})
    page = options[:page] || 1
    matching_users_paginated = MatchingUsersPaginated.new
    matching_users_paginated.page = page.to_i
    matching_users_paginated.results_per_page = DEFAULT_SEARCH_RESULTS_PER_PAGE

    first_5k_follower_ids = get_twitter_follower_ids
    results = MatchingUsersPaginator.find :conditions => ["twitter_id IN (?) AND gender = ? AND interested_in = ?",
                                                          first_5k_follower_ids, interested_in, gender],
                                          :results_per_page => matching_users_paginated.results_per_page,
                                          :page => page
  end
  
  def count_nearby(options)
    self.class.count :conditions => get_nearby_search_conditions(self, options),
                     :origin => [lat, lng], :within => 50
  end

  def who_i_like_count
    liked_users.count
  end
  
  def who_likes_me_count
    liked_by_users.count
  end
  
  def location
    if registered? && city_name.present?
      "#{city_name}, #{Constants::COUNTRIES[country_code]}"
    else
      read_attribute :location
    end
  end
  
  def likes_guys?
    interested_in == "M"
  end
  
  def likes_girls?
    interested_in == "F"
  end
  
  def follows?(user)
    begin
      if twitter.get("/friendships/exists?user_a=#{login}&user_b=#{user.login}") == "true"
        return true
      else
        return false
      end
    rescue TwitterAuth::Dispatcher::Error
      # Likely denied because target user has protected their tweets.
      return false
    end
  end

  def follow(login)
    twitter.post("/friendships/create/#{login}")
  end
  
  def unfollow(login)
    twitter.post("/friendships/destroy/#{login}")
  end
  
  def send_message_to_and_notify(to_user, msg)
    message = messages_from.create msg.merge(:to_user_id => to_user.id)    

    if message.valid?
      message.save!
      if to_user.email.present? && to_user.email_on_new_message?
        Emailer.deliver_message_notification(self, to_user, message)
      elsif to_user.registered? || (to_user.unregistered? && to_user.liked_by_users.blank? && to_user.messages_to.count == 1)
        self.class.send_tweet("@#{to_user.login} Someone on Plenty Of Tweeps sent you a message! In case you're curious: http://potwps.com/inbox")
        if to_user.unregistered?
          self.class.send_tweet("@#{to_user.login} P.S. If you aren't single/looking, sorry for bothering you. We won't send you any more tweets unless you decide to join.")
        end
      end
    end
    
    return message
  end
  
  def build_message_to(user, msg = {})
    msg ||= {}
    messages_from.build msg.merge(:to_user_id => user.id)
  end
  
  def all_messages_to_count
    messages_to.count
  end
  
  def all_unread_messages_count
    unread_messages.count
  end
  
  def paid_member?
    true
  end
  
  def update_login_from_twitter!
    twitter_user_hash = get_user_from_twitter_as_hash(self.twitter_id)
    self.update_attributes!(:login => twitter_user_hash["screen_name"]) unless self.login == twitter_user_hash["screen_name"]
  end
  
  def must_be_18_or_older
    unless birth_date.present? && birth_date.to_date <= 18.years.ago.to_date
      errors.add(:birth_date, "must be 18 or older")
    end
  end
  
  def visible_messages_to
    if paid_member?
      return messages_to
    else
      return messages_from_mutual_admirers
    end
  end
  
  def closest_relationship(twitter_id)
    friend_ids = self.get_twitter_friend_ids
    follower_ids = self.get_twitter_follower_ids

    if friend_ids.present? && friend_ids.include?(twitter_id.to_i)
      return :friend
    elsif follower_ids.present? && follower_ids.include?(twitter_id.to_i)
      return :follower
    else
      return :location
    end
  end

  def get_twitter_user(screen_name)
    Rails.cache.fetch("/users/show/#{screen_name}", :expires_in => 2.hours) {twitter.get("/users/show/#{screen_name}") }
  end
  
  def friend_screen_names
    twitter_friends = get_twitter_friends
    
    twitter_friends.present? ? twitter_friends.map { |f| f["screen_name"] } : []
  end
  
  def screen_name_autocomplete_source
    usernames = Set.new

    self.class.benchmark "loading screen names for autocomplete" do
      usernames.merge(friend_screen_names)
      usernames.merge(liked_users.map { |u| u.login })
      usernames.merge(liked_by_users.map { |u| u.login })
      usernames.merge(smiled_at_users.map { |u| u.login })
      usernames.merge(smiled_at_by_users.map { |u| u.login })
    end

    usernames.to_a.sort { |x, y| x.downcase <=> y.downcase }
  end
  
  def account_type_obj
    case account_type
    when "I"
      INTROVERT
    when "C"
      CONNECTOR
    when "S"
      SOCIAL_SKYDIVER
    end
  end
  
  def daily_smile_limit_reached?
    smiles_sent.in_last_24_hours.count >= account_type_obj.daily_smile_limit
  end
  
  def daily_message_limit_reached?
    messages_from.in_last_24_hours.count >= account_type_obj.daily_message_limit
  end
  
  def daily_like_profile_limit_reached?
    user_likes.in_last_24_hours.count >= account_type_obj.daily_like_profile_limit
  end
  
  def photo_upload_limit_reached?
    photos.count >= account_type_obj.photo_upload_limit
  end
  
  def introvert?
    account_type_obj.account_type == "I"
  end
  
  def connector?
    account_type_obj.account_type == "C"
  end
  
  def social_skydiver?
    account_type_obj.account_type == "S"
  end
  
  def is_paid_up?
    paid_until.present? && paid_until.to_date >= Date.today
  end
  
  def grant_introvert_access
    update_attributes! :account_type => "I", :paid_until => nil, :months_remaining => nil
  end
  
  def grant_connector_access_for(time_period)
    grant_account_access_for(CONNECTOR.account_type, time_period)
  end
  
  def grant_social_skydiver_access_for(time_period)
    grant_account_access_for(SOCIAL_SKYDIVER.account_type, time_period)
  end
  
  def grant_account_access_for(account_type, time_period)
    unless time_period >= 30.days
      raise ArgumentError, "time period for account extension must be at least 30 days"
    end

    update_attributes! :account_type => account_type,
                       :paid_until => Date.today + 30.days,
                       :months_remaining => (time_period / 30.days) - 1    
  end
  
  protected
    
  def like_user(target_username)
    target_user = User.find_by_login_or_import_from_twitter(target_username, self)

    if target_user.present? && !liked_users.include?(target_user)
      liked_users << target_user
      return target_user
    else
      return nil
    end
  end
  
  def send_smile_to_user(target_username)
    target_user = User.find_by_login_or_import_from_twitter(target_username, self)

    if target_user.present? && !has_sent_an_unseen_smile_to?(target_user)
      smiled_at_users << target_user
      return target_user
    else
      return nil
    end
  end
  
  def send_notification_via_twitter_or_email(notification_type, target_user)
    unless [:like, :smile].include?(notification_type)
      raise ArgumentError, "Unknown notification type: #{notification}" 
    end

    return if target_user.unregistered? && (target_user.messages_to.present? ||
                                            target_user.liked_by_users.count > 1 ||
                                            target_user.smiles_received.count > 1)
    
    closest_relationship_symbol = closest_relationship(target_user.twitter_id)
    
    target_username = target_user.login

    case notification_type
    when :like
      msg_clause = "likes you"
      msg_url = someone_likes_url(target_username, :host => 'potwps.com')
    when :smile
      msg_clause = "sent you a smile"
      msg_url = recent_activity_url(:host => 'potwps.com')
    end

    # Note that the text we spit out is the *opposite* of the symbol returned, because
    # the symbol is the relationship of the current user toward the target user.
    if closest_relationship_symbol == :friend
      tweet = "@#{target_username} One of your followers #{msg_clause}! In case you're curious: #{msg_url}"
    elsif closest_relationship_symbol == :follower
      tweet = "@#{target_username} One of your friends #{msg_clause}! In case you're curious: #{msg_url}"
    else
      tweet = "@#{target_username} Someone in #{city_name} #{msg_clause}! In case you're curious: #{msg_url}"
    end
  
    if target_user.email.present? && target_user.email_on_new_message?
      Emailer.send(:"deliver_#{notification_type}_notification", self, target_user, closest_relationship_symbol)
    else
      User.send_tweet(tweet)
      if target_user.unregistered?
        User.send_tweet("@#{target_username} P.S. If you aren't single/looking, sorry for bothering you. We won't send you any more tweets unless you decide to join.")
      end
    end
  end

  def get_twitter_friends
    friends_statuses_url_template = "/statuses/friends?cursor=%s&twitter_id=#{self.twitter_id}"
    twitter_friends_path =  friends_statuses_url_template % "-1"
    Rails.cache.fetch(twitter_friends_path, :expires_in => 1.day) do
      results = []
      10.times do
        results_cursor = twitter.get(twitter_friends_path)
        results += results_cursor["users"] || []
        next_cursor_str = results_cursor["next_cursor_str"]
        break if next_cursor_str == "0" || next_cursor_str.blank?
        twitter_friends_path = friends_statuses_url_template % next_cursor_str
      end
      results
    end
  end
  
  def get_twitter_followers(options = {})
    options[:page] ||= 1
    twitter_followers_path = "/statuses/followers?page=#{options[:page]}&twitter_id=#{self.twitter_id}"
    Rails.cache.fetch(twitter_followers_path, :expires_in => 2.hours) { twitter.get(twitter_followers_path) }
  end
  
  # TODO: This will currently only grab the first 5000 friend IDs,
  # as per the Twitter API limitation here:
  #
  # http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-friends%C2%A0ids
  #
  # Brad Bollenbach, 2009-09-24
  def get_twitter_friend_ids
    friend_ids_path = "/friends/ids?twitter_id=#{self.twitter_id}"
    Rails.cache.fetch(friend_ids_path, :expires_in => 2.hours) { twitter.get(friend_ids_path) }
  end
  
  def get_twitter_follower_ids
    follower_ids_path = "/followers/ids?twitter_id=#{self.twitter_id}"
    Rails.cache.fetch(follower_ids_path, :expires_in => 2.hours) { twitter.get(follower_ids_path) }
  end
  
end
