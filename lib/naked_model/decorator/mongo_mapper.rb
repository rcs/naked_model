require 'mongo_mapper'

# String methods
require 'active_support'

class NakedModel::Decorator::MongoMapper
  require_relative 'mongo_mapper/object'
  require_relative 'mongo_mapper/collection'
  attr_accessor :models

  # Pull all the MM classes into our models hash
  def initialize
    self.models = Hash[
      MongoMapper::Document.descendants.map { |c|
        [c.name.tableize, c]
      }
    ]
  end

  # Return all the models as relations to this playground
  def as_json(request)
    {
      :links => models.map { |k,v| {:rel => k, :href => [k] } }
    }
  end

  def rel(relation)
    # TODO raise error on no key
    models[relation]
  end

  def decorate(obj)
    if obj.class <  MongoMapper::Document
      NakedModel::Decorator::MongoMapper::Object.new obj
    elsif collection? obj
      NakedModel::Decorator::MongoMapper::Collection.new obj 
    elsif obj.is_a? Proc
      NakedModel::Decorator::Curried.new obj
    else
      $stderr.puts "Couldn't decorate #{obj.inspect}"
      raise NoMethodError.new(obj)
    end
  end

  def collection?(obj)
    # Trivial case
    return obj if obj.is_a? Class and obj < ::MongoMapper::Document

    # Plucky::Queries embed the underlying class as `.model`
    if obj.is_a? ::Plucky::Query
      obj.model
    elsif obj.is_a? ::Array
      # Associations masquerade as an `Array` (author.books), so try to find the proxy_association's class
      begin
        obj.proxy_association.klass
      rescue NoMethodError
        nil
      end
    else
      nil
    end

  end
end
