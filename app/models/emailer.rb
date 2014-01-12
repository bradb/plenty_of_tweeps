class Emailer < ActionMailer::Base

  def message_notification(from_user, to_user, message)
    return unless to_user.email_on_new_message?

    from 'noreply@plentyoftweeps.com'
    recipients to_user.email

    if to_user.paid_member? || from_user.paid_member? || to_user.mutual_admirers.include?(from_user)
      subject "#{from_user.login} sent you a message on Plenty of Tweeps"
      template "message_notification"
    else
      subject "Someone sent you a message on Plenty of Tweeps"
      template "generic_message_notification"
    end
    body :from_user => from_user, :to_user => to_user, :message => message
  end
  
  def like_notification(source_user, target_user, closest_relationship_symbol)
    return unless target_user.email_on_new_message?
    
    from 'noreply@plentyoftweeps.com'
    recipients target_user.email
    body :liked_user => target_user
    subject "Someone on Plenty of Tweeps likes your profile!"
  end
  
  def liked_user_joined_notification(liked_user, liked_by_user)
    return unless liked_by_user.email.present? && liked_by_user.email_on_new_message?
    
    from 'noreply@plentyoftweeps.com'
    recipients liked_by_user.email
    
    body :just_joined_user => liked_user, :to_user => liked_by_user
    subject "Someone you liked joined Plenty of Tweeps!"
  end

  def smile_notification(source_user, target_user, closest_relationship_symbol)
    return unless target_user.email.present? && target_user.email_on_new_message?
    
    from 'noreply@plentyoftweeps.com'
    recipients target_user.email
    
    body :target_user => target_user
    subject "Someone on Plenty of Tweeps sent you a smile!"
  end

  def smile_recipient_joined_notification(smile_recipient, smile_sender)
    return unless smile_sender.email.present? && smile_sender.email_on_new_message?
    
    from 'noreply@plentyoftweeps.com'
    recipients smile_sender.email
    
    body :smile_recipient => smile_recipient, :smile_sender => smile_sender
    subject "Someone you smiled at joined Plenty of Tweeps!"
  end

  def welcome_message(to_user)
    from 'noreply@plentyoftweeps.com'
    recipients to_user.email
    body :user => to_user
    subject "Welcome to Plenty of Tweeps!"
  end
  
  def nearby_matches_notification(to_user)
    from 'noreply@plentyoftweeps.com'
    recipients to_user.email
    body :to_user => to_user, :matching_users => to_user.find_nearby(:order => "RAND()", :limit => 8)
    subject "Your latest matches on Plenty of Tweeps!"
    content_type "text/html"
  end

end
