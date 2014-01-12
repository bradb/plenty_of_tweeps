class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      ### TwitterAuth migration stuff ###
      t.string :twitter_id
      t.string :login
      t.string :access_token
      t.string :access_secret

      t.string :remember_token
      t.datetime :remember_token_expires_at

      # This information is automatically kept
      # in-sync at each login of the user. You
      # may remove any/all of these columns.
      t.string :name
      t.string :location
      t.string :description
      t.string :profile_image_url
      t.string :url
      t.boolean :protected
      t.integer :friends_count
      t.integer :statuses_count
      t.integer :followers_count
      t.integer :favourites_count

      # Probably don't need both, but they're here.
      t.integer :utc_offset
      t.string :time_zone
      ### End TwitterAuth migration stuff ###
      
      ### Custom Plenty of Tweeps columns ###
      t.string :gender, :limit => 1
      t.date :birth_date
      t.string :interested_in, :limit => 1
      t.string :postal_code
      t.string :email
      t.integer :min_age
      t.integer :max_age
      
      ### For mapping
      t.decimal :lat ,  :precision => 10, :scale => 6
      t.decimal :lng ,  :precision => 10, :scale => 6
      t.string  :city_name
      t.string  :prov_state_code
      t.string  :country_code
      
      t.datetime :joined_on
      t.datetime :last_online
      ### End custom Plenty of Tweeps columns ###

      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
