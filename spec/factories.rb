require 'factory_girl'

Factory.sequence :email do |n|
  "tweep#{n}@plentyoftweeps.com"
end

Factory.sequence :profile_image_url do |n|
  "http://s.twimg.com/a/1253830975/images/default_profile_"+rand(7).to_s+"_bigger.png"
end

Factory.define :unregistered_user, :class => User do |u|
  u.sequence(:twitter_id) { |n| "123456#{n}".to_i }
  u.sequence(:login) { |n| "tweep#{n}" }
  u.sequence(:profile_image_url) { Factory.next(:profile_image_url) }
end

Factory.define :registered_guy, :parent => :unregistered_user do |u|
  u.joined_on 1.week.ago
  u.birth_date 25.years.ago
  u.email { Factory.next(:email) }
  u.profile_image_url { Factory.next(:profile_image_url) }
  u.email_on_new_message true
  u.gender "M"
  u.interested_in "F"
  u.friends_count 50
  u.followers_count 200
  u.min_age 24
  u.max_age 30
  u.city_name "Vancouver"
  u.lng -123.138565
  u.lat 49.263588
  u.country_code "CA"
  u.prov_state_code "BC"
end

Factory.define :introvert_guy, :parent => :registered_guy do |u|
  u.account_type { INTROVERT.account_type }
end

Factory.define :connector_guy, :parent => :registered_guy do |u|
  u.account_type { CONNECTOR.account_type }
  u.paid_until 2.weeks.from_now
  u.months_remaining 3
end

Factory.define :social_skydiver_guy, :parent => :registered_guy do |u|
  u.account_type { SOCIAL_SKYDIVER.account_type }
  u.paid_until 2.weeks.from_now
  u.months_remaining 3
end

Factory.define :registered_girl, :parent => :registered_guy do |u|
  u.gender "F"
  u.interested_in "M"
end

Factory.define :registered_girl_whistler, :parent => :registered_girl do |u|
  u.city_name "Whistler"
  u.lng -122.959146
  u.lat 50.115248
end

Factory.define :registered_girl_victoria, :parent => :registered_girl do |u|
  u.city_name "Victoria"
  u.lng -123.367259
  u.lat 48.4275
end

Factory.define :registered_lesbian_victoria, :parent => :registered_girl do |u|
  u.gender "F"
  u.interested_in "F"
  u.city_name "Victoria"
  u.lng -123.367259
  u.lat 48.4275  
end

Factory.define :registered_girl_sydney, :parent => :registered_girl do |u|
  u.city_name "Sydney"
  u.lng 151.207114
  u.lat -33.867139
end


Factory.define :registered_random_user, :parent => :unregistered_user do |u|
  u.joined_on 1.week.ago
  u.birth_date 25.years.ago
  u.email { Faker::Internet.email }
  u.profile_image_url { Factory.next(:profile_image_url) }
  u.description "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor."
  u.gender { ['M','F'].rand.to_s }
  u.interested_in { ['M','F'].rand.to_s }
  u.min_age 19
  u.max_age { rand(40)+19 }
  u.lat { rand(3)+49+ Integer(rand() * 1000000) / Float(1000000) }
  u.lng { ((rand(11)+114+ Integer(rand() * 1000000) / Float(1000000)) * -1) }
  u.city_name {Faker::Address.city}
  u.prov_state_code {Faker::Address.us_state_abbr()}
  u.country_code {['CA','US'].rand.to_s}
  u.postal_code {Faker::Address.zip_code()}
end

Factory.define :registered_random_user, :parent => :unregistered_user do |u|
  u.joined_on 1.week.ago
  u.birth_date 25.years.ago
  u.email { Faker::Internet.email }
  u.profile_image_url { Factory.next(:profile_image_url) }
  u.description "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor."
  u.gender { ['M','F'].rand.to_s }
  u.interested_in { ['M','F'].rand.to_s }
  u.min_age 19
  u.max_age { rand(40)+19 }
  u.lat { rand(3)+49+ Integer(rand() * 1000000) / Float(1000000) }
  u.lng { ((rand(11)+114+ Integer(rand() * 1000000) / Float(1000000)) * -1) }
  u.city_name {Faker::Address.city}
  u.prov_state_code {Faker::Address.us_state_abbr()}
  u.country_code {['CA','US'].rand.to_s}
  u.postal_code {Faker::Address.zip_code()}
end

Factory.sequence(:subject) { |n| "Subject #{n}" }
Factory.sequence(:body) { |n| "Body #{n}" }

Factory.define :message do |m|
  m.association :from_user, :factory => :registered_guy
  m.association :to_user, :factory => :registered_girl 
  m.subject { Factory.next(:subject) }
  m.body { Factory.next(:body) }
end

Factory.sequence(:file_name) { |n| "tallinn-#{n}.jpg" }

Factory.define :photo do |p|
  p.data_file_name { Factory.next(:file_name) }
  p.data_content_type "image/jpeg"
  p.data_file_size 4242
  p.association(:user)
end

Factory.define :user_like do |ul|
  ul.association :source_user, :factory => :registered_guy
  ul.association :target_user, :factory => :registered_girl
end

Factory.define :smile do |s|
  s.association :source_user, :factory => :registered_guy
  s.association :target_user, :factory => :registered_girl
end