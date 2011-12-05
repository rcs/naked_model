require './lib/naked_model'
require './lib/naked_model/adapter/mongo_mapper'
require './spec/factory/mm'

use Rack::Static, :urls => ["/css","/javascripts","/pages"], :root => "public"
run NakedModel.new( :adapters => [NakedModel::Adapter::MongoMapper::Collection.new, NakedModel::Adapter::MongoMapper::Object.new] )
