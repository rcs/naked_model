require 'factory_girl'
require 'active_record'


ActiveRecord::Base.configurations['ar'] = {
  :adapter => 'sqlite3',
  :database => File.dirname(__FILE__) + "/ar_test.sqlite3"
}


ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['ar'])
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

class BaseSqlAr < ActiveRecord::Base
  establish_connection 'ar'
  self.abstract_class = true
end

class Artist < BaseSqlAr
  has_many :cds

  validates_length_of :name, :minimum => 1
  validates_uniqueness_of :name

  def llamas
    'truly rock'
  end
end
class Cd < BaseSqlAr
  belongs_to :artist
  has_many :tracks
end
class Track < BaseSqlAr
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
