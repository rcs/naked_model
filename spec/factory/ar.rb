require 'factory_girl'
require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => File.dirname(__FILE__) + "/test.sqlite3"
)


ActiveRecord::Schema.define do
  create_table "artists", :force => true do |t|
    t.text     "name"
  end
  create_table "cds", :force => true do |t|
    t.integer  "artist_id"
    t.text     "title"
  end

  create_table "tracks", :force => true do |t|
    t.integer  "trackid"
    t.text     "title"
    t.integer  "cd_id"
  end
end

class Artist < ActiveRecord::Base
  has_many :cds

  def llamas
    'truly rock'
  end
end
class Cd < ActiveRecord::Base
  belongs_to :artist
  has_many :tracks
end
class Track < ActiveRecord::Base
  scope :including_one_in_title, where("title like '%1%'")
  belongs_to :cd
end


FactoryGirl.define do
  factory :artist do
    sequence(:name) {|n| "Artist#{n}"}

    factory :prolific_artist do
      cds { FactoryGirl.create_list(:cd_with_tracks, 5) }
    end
  end

  factory :cd do
    sequence(:title) {|n| "Album#{n}"}
    factory :cd_with_artist do
      assocation :artist
    end
    factory :cd_with_tracks do
      tracks { FactoryGirl.create_list(:track, 10) }
    end
  end

  factory :track do
    sequence(:title) {|n| "Track#{n}"}
  end
end
