require 'mongo_mapper'
require 'factory_girl'

MongoMapper.database = 'nr_test'

class Author
  include MongoMapper::Document

  def do_books_rock
    "yes"
  end

  key :name

  many :books
  one :desk
end

class Book
  include MongoMapper::Document

  scope :published, lambda { where(:published => true) }
  scope :includes_6, lambda { where(:title => /6/ ) }



  key :published
  key :title

  belongs_to :author
end

class Desk
  include MongoMapper::Document

  belongs_to :author
end

FactoryGirl.define do
  factory :author do
    sequence(:name) {|n| "Author#{n}"}

    factory :prolific_author do
      books { FactoryGirl.create_list(:book, 5) + FactoryGirl.create_list(:published_book, 5)}
    end
  end

  factory :book do
    sequence(:title) {|n| "Book#{n}"}
    factory :book_with_author do
      assocation :author
    end
    factory :published_book do
      published true
    end
  end
end
