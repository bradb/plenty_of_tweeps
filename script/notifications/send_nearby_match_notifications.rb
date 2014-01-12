#!/usr/bin/env ruby

require 'optparse'

options = {}

optparse = OptionParser.new do|opts|
  # Set a banner, displayed at the top
  # of the help screen.
  opts.banner = "Usage: send_nearby_match_notifications.rb [options]"

  # Define the options, and what they do
  options[:notify_all] = false
  opts.on('-a', '--all', 'Send notifications to all users' ) do
    options[:notify_all] = true
  end

  options[:user] = nil
  opts.on( '-u', '--user login', 'Send notifications to only a specific user' ) do |login|
    options[:user] = login
  end

  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

optparse.parse!

if options[:user] && options[:notify_all]
  puts "You must specific either a user (-u) OR all (-a), but not both"
  exit
end

if options[:user]
  user = User.find_by_login(options[:user])
  unless user
    puts "Couldn't find user #{options[:user]}"
    exit
  end

  unless user.email_matches_notification?
    puts "\n*** ERROR *** #{user.login} has email_matches_notification set to false. No email sent."
    exit
  end
  
  unless user.email.present?
    puts "\n*** ERROR *** #{user.login} has not provided an email address. No email sent."
    exit
  end
  
  Emailer.deliver_nearby_matches_notification(user)
end