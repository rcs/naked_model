$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'naked_model'
require 'naked_model/decorator/mongo_mapper'
require './spec/factory/mm'

use Rack::Static, :urls => ["/stylesheets","/javascripts","/pages"], :root => "public"
run NakedModel.new NakedModel::Decorator::MongoMapper.new
