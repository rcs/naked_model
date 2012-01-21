require 'active_record'

class NakedModel::Decorator::ActiveRecord
  require_relative 'active_record/object'
  require_relative 'active_record/collection'
  require_relative 'curried'
  attr_accessor :models

  # Pull all the AR classes into our models hash
  def initialize
    self.models = Hash[
      ActiveRecord::Base.descendants.select(&:name).select { |c| !c.abstract_class }.map { |c|
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

  def rel(request)
    # TODO raise error on no key
    models.fetch request
  end

  def decorate(obj)
    if obj.class < ActiveRecord::Base
      NakedModel::Decorator::ActiveRecord::Object.new obj
    elsif collection? obj
      NakedModel::Decorator::ActiveRecord::Collection.new obj 
    elsif obj.is_a? Proc
      NakedModel::Decorator::Proc.new obj
    else
      $stderr.puts "Couldn't decorate #{obj.inspect}"
      raise NakedModel::NoMethodError
    end
  end

  def collection?(obj)
    NakedModel::Decorator::ActiveRecord::Collection.collection_class obj 
  end
end
