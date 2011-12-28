require 'mongo_mapper'

# String methods
require 'active_support'

module NakedModel::Adapter::MongoMapper
  require_relative 'mongo_mapper/object'
  require_relative 'mongo_mapper/collection'

  def platonic_class(klass)
    platonic = Class.new
    platonic.class_eval { include ::MongoMapper::Document }
    platonic
  end

  def association_names(obj)
    klass = obj.class
    klass.associations.values.map { |m| m.name }
  end

end
