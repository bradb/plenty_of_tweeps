# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100520202408) do

  create_table "actions", :force => true do |t|
    t.integer  "item_id"
    t.string   "item_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cities", :force => true do |t|
    t.string  "name",       :limit => 200
    t.decimal "latitude",                  :precision => 10, :scale => 6
    t.decimal "longitude",                 :precision => 10, :scale => 6
    t.string  "country",    :limit => 2
    t.string  "prov_state", :limit => 20
    t.string  "timezone",   :limit => 40
    t.date    "moddate"
  end

  create_table "messages", :force => true do |t|
    t.integer  "from_user_id"
    t.integer  "to_user_id"
    t.string   "subject"
    t.text     "body"
    t.boolean  "unread",       :default => true
    t.boolean  "deleted",      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payment_notifications", :force => true do |t|
    t.text     "params"
    t.integer  "paypal_transaction_id"
    t.string   "status"
    t.string   "txn_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "paypal_transactions", :force => true do |t|
    t.integer  "user_id"
    t.datetime "purchased_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "photos", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "data_file_name"
    t.string   "data_content_type"
    t.integer  "data_file_size"
  end

  add_index "photos", ["user_id"], :name => "index_photos_on_user_id"

  create_table "profile_views", :force => true do |t|
    t.integer  "viewed_by_user_id"
    t.integer  "seen_user_id"
    t.integer  "deleted"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "smiles", :force => true do |t|
    t.integer  "source_user_id"
    t.integer  "target_user_id"
    t.boolean  "deleted",        :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_likes", :force => true do |t|
    t.integer  "source_user_id"
    t.integer  "target_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "twitter_id"
    t.string   "login"
    t.string   "access_token"
    t.string   "access_secret"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "name"
    t.string   "location"
    t.string   "description"
    t.string   "profile_image_url"
    t.string   "url"
    t.boolean  "protected"
    t.integer  "friends_count"
    t.integer  "statuses_count"
    t.integer  "followers_count"
    t.integer  "favourites_count"
    t.integer  "utc_offset"
    t.string   "time_zone"
    t.string   "gender",                            :limit => 1
    t.date     "birth_date"
    t.string   "interested_in",                     :limit => 1
    t.string   "postal_code"
    t.string   "email"
    t.integer  "min_age"
    t.integer  "max_age"
    t.decimal  "lat",                                            :precision => 10, :scale => 6
    t.decimal  "lng",                                            :precision => 10, :scale => 6
    t.string   "city_name"
    t.string   "prov_state_code"
    t.string   "country_code"
    t.datetime "joined_on"
    t.datetime "last_online"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "paid_until"
    t.text     "extended_bio"
    t.boolean  "email_on_new_message",                                                          :default => true
    t.boolean  "email_matches_notification",                                                    :default => true
    t.datetime "last_matches_notification_sent_at"
    t.string   "account_type",                      :limit => 1,                                :default => "I"
    t.integer  "months_remaining"
  end

end
