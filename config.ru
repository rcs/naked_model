$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'naked_model'
require 'naked_model/decorator/mongo_mapper'
require './spec/factory/mm'

require 'naked_model/decorator/active_record'
require './spec/factory/ar'

use Rack::Static, :urls => ["/stylesheets","/javascripts","/pages"], :root => "public"

app = Rack::Builder.new do
  map '/ar/' do
    Factory(:prolific_artist)
    run NakedModel.new NakedModel::Decorator::ActiveRecord.new
  end
  map '/mm/' do
    run NakedModel.new NakedModel::Decorator::MongoMapper.new
  end
end

run app
