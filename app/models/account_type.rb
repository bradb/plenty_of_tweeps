class AccountType
  attr_accessor :daily_smile_limit, :daily_message_limit, :daily_like_profile_limit,
                :photo_upload_limit, :can_see_site_wide_image_gallery,
                :can_see_who_has_viewed_their_profile, :candidate_for_premium_ads,
                :display_name, :account_type, :price
                
  def initialize(options = {})
    options.assert_valid_keys(:daily_smile_limit, :daily_message_limit, :daily_like_profile_limit,
                              :photo_upload_limit, :can_see_site_wide_image_gallery,
                              :can_see_who_has_viewed_their_profile, :candidate_for_premium_ads,
                              :can_see_sent_messages_read, :display_name, :account_type, :price)
    
    @can_see_site_wide_image_gallery = options[:can_see_site_wide_image_gallery] || false
    @can_see_who_has_viewed_their_profile = options[:can_see_who_has_viewed_their_profile] || false
    @can_see_sent_messages_read = options[:can_see_sent_messages_read] || false
    @candidate_for_premium_ads = options[:candidate_for_premium_ads] || false
    @daily_smile_limit = options[:daily_smile_limit]
    @daily_message_limit = options[:daily_message_limit]
    @daily_like_profile_limit = options[:daily_like_profile_limit]
    @photo_upload_limit = options[:photo_upload_limit]
    @account_type = options[:account_type]
    @display_name = options[:display_name]
    @price = options[:price]
  end

  def can_see_site_wide_image_gallery?
    @can_see_site_wide_image_gallery
  end
  
  def can_see_sent_messages_read?
    @can_see_sent_messages_read
  end
  
  def can_see_who_has_viewed_their_profile?
    @can_see_who_has_viewed_their_profile
  end
  
  def candidate_for_premium_ads?
    @candidate_for_premium_ads
  end
  
end