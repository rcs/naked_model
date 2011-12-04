require './lib/naked_model'
require './lib/naked_model/adapter/mongo_mapper'
require './spec/factory/mm'

run NakedModel.new( :adapters => [NakedModel::Adapter::MongoMapper::Collection.new, NakedModel::Adapter::MongoMapper::Object.new] )
