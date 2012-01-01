require_relative '../orm_namespace'
require_relative '../active_model/collection'
class NakedModel::Adapter::ActiveRecord::Collection < NakedModel::Adapter
  include NakedModel::Adapter::OrmNamespace
  include NakedModel::Adapter::ActiveRecord
  include NakedModel::Adapter::ActiveModel::Collection

  # The classes we care about inherit from `ActiveRecord::Base`
  def initialize
    @orm_classes = ar_classes
  end

  # Create a new object on the collection from the `request.body`
  def create(request)
    begin
      created = request.target.create!(request.body)
      request.next created, :path => [created.id.to_s]
    rescue ::ActiveRecord::RecordInvalid => e
      raise NakedModel::CreateError.new e
    end
  end

  # We care about this object if it's a collection class we care about
  def handles?(request)
    collection_class(request.target)
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

    if klass.ancestors & ar_classes
      klass
    else
      nil
    end
  end

  # By default, we display all elements of the collection
  def display(obj)
    obj.all.map do |a|
      # TODO NakedModel::display(obj)
      a.as_json.merge(
      {
        :links => [
          { :rel => 'self', :href => ['.', a.id.to_s] },
          *a.class.reflect_on_all_associations.map { |m| {:rel => m.name.to_s, :href => ['.',m.name.to_s]}}
        ]})
    end
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
