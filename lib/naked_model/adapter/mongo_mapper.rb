require 'mongo_mapper'
require 'active_support'

module NakedModel::Adapter::MongoMapper
  require_relative 'mongo_mapper/object'
  require_relative 'mongo_mapper/collection'

  def platonic_class(klass)
    platonic = Class.new
    platonic.class_eval { include ::MongoMapper::Document }
    platonic
  end

end
