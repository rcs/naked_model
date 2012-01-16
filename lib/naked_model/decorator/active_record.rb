require 'active_record'

class NakedModel::Decorator::ActiveRecord
  attr_accessor :models

  # Pull all the AR classes into our models hash
  def initialize
    self.models = Hash[
      ActiveRecord::Base.descendants.map { |c|
        [c.name.tableize, c]
      }
    ]
  end

  # Return all the models as relations to this playground
  def as_json
    {
      :links => models.map { |k,v| {:rel => k, :href => [v.tableize.to_s] } }
    }
  end

  def rel(request)
    # TODO raise error on no key
    models.fetch request
  end

  def decorate(obj)
    if obj.class.ancestors & ActiveRecord::Base
      NakedModel::Decorator::ActiveRecord::Object.new obj
    elsif collection? obj
      NakedModel::Decorator::ActiveRecord::Collection.new obj 
    elsif obj.is_a? Proc
      NakedModel::Decorator::Curried.new obj
    else
      raise NakedModel::NoMethodError
    end
  end

  def collection?
    if obj.is_a? Class
      klass = obj
    elsif obj.is_a? ::ActiveRecord::Relation
      klass = obj.klass
    else
      begin
        klass = obj.proxy_association.reflection.klass
      rescue NoMethodError
        return nil
      end
    end

    if klass.ancestors & ActiveRecord::Base
      true
    else
      nil
    end
  end
end
