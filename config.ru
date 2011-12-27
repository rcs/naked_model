$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'naked_model'
require 'naked_model/adapter/mongo_mapper'
require './spec/factory/mm'

use Rack::Static, :urls => ["/stylesheets","/javascripts","/pages"], :root => "public"
run NakedModel.new( 
  :adapters => [
    NakedModel::Adapter::MongoMapper::Collection.new,
    NakedModel::Adapter::MongoMapper::Object.new,
    NakedModel::Adapter::Hash.new( 'hash' => { 'one' => 1, 'two' => 2, 'deep' => { 'deeper' => 3 } } ),
] )
