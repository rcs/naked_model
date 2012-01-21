require 'mongo_mapper'
# String methods
require 'active_support'

class NakedModel::Decorator::MongoMapper
  require_relative 'mongo_mapper/object'
  require_relative 'mongo_mapper/collection'
  require_relative 'curried'
  attr_accessor :models

  # Pull all the MM classes into our models hash
  def initialize
    self.models = Hash[
      MongoMapper::Document.descendants.select { |c| c.name }.map { |c|
        [c.name.tableize, c]
      }
    ]
  end

  # Return all the models as relations to this playground
  def as_json(request)
    {
      :links => [
        *models.map { |k,v| {:rel => k, :href => request.add_path(k).full_path } },
        {:rel => 'self', :href => request.full_path}
      ]
    }
  end

  def rel(relation)
    # TODO raise error on no key
    models.fetch relation
  end

  def decorate(obj)
    if obj.class <  MongoMapper::Document
      NakedModel::Decorator::MongoMapper::Object.new obj
    elsif collection? obj
      NakedModel::Decorator::MongoMapper::Collection.new obj 
    elsif obj.is_a? Proc
      NakedModel::Decorator::Proc.new obj
    else
      $stderr.puts "Couldn't decorate #{obj.inspect}"
      raise NoMethodError.new(obj)
    end
  end

  def collection?(obj)
    NakedModel::Decorator::MongoMapper::Collection.collection_class obj
  end
end
