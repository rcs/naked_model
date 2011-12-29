require 'mongo_mapper'

# String methods
require 'active_support'

# Basic helpe  methods for `MongoMapper` adapters
module NakedModel::Adapter::MongoMapper
  require_relative 'mongo_mapper/object'
  require_relative 'mongo_mapper/collection'

  # Create an anonymous class modeling an empty `MongoMapper::Document`
  def platonic_class(klass)
    platonic = Class.new
    platonic.class_eval { include ::MongoMapper::Document }
    platonic
  end

  # Find the associations that `obj` has
  def association_names(obj)
    klass = obj.class
    klass.associations.values.map { |m| m.name }
  end

end
