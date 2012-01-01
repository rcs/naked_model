require 'naked_model/adapter/orm_namespace'
require 'naked_model/adapter/active_model/collection'

class NakedModel::Adapter::MongoMapper::Collection < NakedModel::Adapter
  include NakedModel::Adapter::MongoMapper
  include NakedModel::Adapter::OrmNamespace
  include NakedModel::Adapter::ActiveModel::Collection

  # We'll care about `MongoMapper::Document` derived classes
  def initialize
    @orm_classes = [::MongoMapper::Document]
  end

  # Create an object on the collection, raising `CreateError` with the message if it fails
  def create(request)
    begin
      created = request.target.create!(request.body)
      request.next created, :path => [created.id.to_s]
    rescue ::MongoMapper::DocumentNotValid => e
      raise NakedModel::CreateError.new e.message
    end
  end

  # We'll handle this class if it's a collection class we care about
  def handles?(request)
    collection_class(request.target)
  end

  # Return all MongoMapper derived class names loaded, with links to their endpoints
  def all_names
    ::MongoMapper::Document.descendants.select { |a| orm_class? a.to_s }.map { |a|
        { :rel => a.to_s.underscore.pluralize, :href => ['.' , a.to_s.underscore] }
    }
  end

  # Return the MongoMapper::Document class underlying the object, or nil if it doesn't exist
  def collection_class(obj)
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

  # Return the elements in the collection, and their associations
  def display(obj)
    obj.all.map do |a|
      # TODO NakedModel::display(obj)
      a.as_json.merge(
      {
        :links => [
          { :rel => 'self', :href => ['.', a.id.to_s] },
          *association_names(a).map { |n| {:rel => n.to_s, :href => ['.',n.to_s]}}
        ]})
    end
  end

  # Call the base `Adapter` call_proc, trying to find the `method` as an id in the collection if it fails
  def call_proc(request)
    begin
      super
    rescue NoMethodError
      # Mongo ids are hexadecimal
      if /^[[:xdigit:]]+$/ === request.method
        res = request.target.find(request.method)
        raise NakedModel::RecordNotFound if res.nil?
        request.next res
      else
        raise NoMethodError.new(request.method)
      end
    end
  end

end
