class CreateCities < ActiveRecord::Migration
  def self.up
    create_table "cities", :force => true do |t|
      t.string  "name",           :limit => 200
      t.decimal "latitude",                       :precision => 10, :scale => 6
      t.decimal "longitude",                      :precision => 10, :scale => 6
      t.string  "country",        :limit => 2
      t.string  "prov_state",         :limit => 20
      t.string  "timezone",       :limit => 40
      t.date    "moddate"
    end
  end

  def self.down
    drop_table :cities
  end
end
