require_relative '../orm_namespace'
require_relative '../active_model/collection'
class NakedModel::Adapter::ActiveRecord::Collection < NakedModel::Adapter
  include NakedModel::Adapter::OrmNamespace
  include NakedModel::Adapter::ActiveRecord
  include NakedModel::Adapter::ActiveModel::Collection

  # The classes we care about inherit from `ActiveRecord::Base`
  def initialize
    @orm_classes = [::ActiveRecord::Base]
  end

  # Create a new object on the collection from the `request.body`
  def create(request)
    request.target.create(request.body)
  end

  # We care about this object if it's a collection class we care about
  def handles?(*chain)
    collection_class(chain.first)
  end

  # Return the ActiveRecord inheriting class that underlies this `obj`, or nil if it doesn't exist
  def collection_class(obj)
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

    if klass < ::ActiveRecord::Base
      klass
    else
      nil
    end
  end

  # By default, we display all elements of the collection
  def display(obj)
    obj.all
  end

  # Call base `Adapter` call_proc, trying to find the `method` as an id on the
  # collection if it's not a method
  def call_proc(request)
    begin
      super
    rescue NoMethodError => e
      # Rethrow error if `method` doesn't look like an id
      raise e unless is_num? request.method

      # Use `method` as an id to find, raising `RecordNotFound` if it can't be found
      begin
        request.next request.target.find(request.method) 
      rescue ::ActiveRecord::RecordNotFound
        raise NakedModel::RecordNotFound.new(request.method)
      end
    end
  end

end
