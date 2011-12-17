require 'factory_girl'
require 'active_record'

ActiveRecord::Base.configurations['ar_warden'] = {
  :adapter => 'sqlite3',
  :database => File.dirname(__FILE__) + "/#{File.basename(__FILE__)}.sqlite3"
}

ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['ar_warden'])

ActiveRecord::Schema.define do
  create_table "users", :force => true do |t|
    t.text "name"
  end

  create_table "things", :force => true do |t|
    t.text "name"
    t.text "description"
    t.integer "user_id"
  end
end

class BaseSqlWarden < ActiveRecord::Base
  establish_connection 'ar_warden'
  self.abstract_class = true
end

class Thing < BaseSqlWarden

end

class User < BaseSqlWarden
  has_many :things
end


FactoryGirl.define do
  factory :user do
    sequence(:name) {|n| "User#{n}"}

    factory :prolific_user do
      things { FactoryGirl.create_list(:thing, 5) }
    end
  end

  factory :thing do
    sequence(:name) { |n| "Thing#{n}" }
    sequence(:description) { |n| "SillyDescription#{n}" }
  end
end
