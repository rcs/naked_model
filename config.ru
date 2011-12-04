require './lib/naked_record'
require './lib/naked_record/adapter/mongo_mapper'
require './spec/factory/mm'

run NakedRecord.new( :adapters => [NakedRecord::Adapter::MongoMapper::Collection.new, NakedRecord::Adapter::MongoMapper::Object.new] )
