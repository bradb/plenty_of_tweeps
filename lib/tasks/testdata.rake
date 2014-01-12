namespace :db do
  namespace :testdata do
    desc "Load test data using factories instead of fixtures"
    task :load => :environment do
      require "spec/factories"
      User.delete_all
      UserLike.delete_all
      Action.delete_all
      Photo.delete_all
      Message.delete_all
      PaymentNotification.delete_all
      PaypalTransaction.delete_all

      Factory.create :registered_guy,
                     :twitter_id => "6453492",
                     :login => "30sleeps",
                     :birth_date => "1978-11-19",
                     :profile_image_url => "http://a1.twimg.com/profile_images/51763742/techno_toque_bigger.jpg",
                     :description => "I write about the pursuit of happiness, and the joy of living dangerously."

      Factory.create :registered_guy,
                     :twitter_id => "14174460",
                     :login => "bollenbach",
                     :birth_date => "1987-11-06",
                     :profile_image_url => "http://a1.twimg.com/profile_images/59392246/pub_bigger.jpg",
                     :description => "My name is Ryan Bollenbach and I'm a Web Designer for Tungle. I love mixing music, mainly Electrohouse, Minimal and Tech House."

      Factory.create :registered_girl,
                     :twitter_id => "14019082",
                     :login => "melissa",
                     :birth_date => 24.years.ago,
                     :profile_image_url => "http://a1.twimg.com/profile_images/125633192/avatar2_bigger.jpg",
                     :description => "An uber geek who is obsessed with technology, education, search engines, start-ups, and China. Also in love with @johnerik."

      Factory.create :registered_girl,
                     :twitter_id => "39820382",
                     :login => "SimoneKaminsky",
                     :birth_date => 28.years.ago,
                     :profile_image_url => "http://a3.twimg.com/profile_images/400101543/Picture_2_bigger.png",
                     :description => "Love design, photography, the ocean, nature, creativity, beauty and  adventure!"
                     
      for k in 1..100
        Factory.create :registered_random_user
      end
    end
  end
end