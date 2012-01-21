class NakedModel::Decorator::MongoMapper::Collection
  def self.collection_class(obj)
    # Trivial case
    if obj.is_a? Class
      klass = obj
    else
      # obj.model from Plucky::Query, klass from MongoMapper::Plugins::Associations::Proxy
      klass = (obj.model rescue nil) || (obj.klass rescue nil)
    end

    if klass < ::MongoMapper::Document
      klass
    else
      nil
    end
  end

  attr_accessor :collection
  def initialize(collection)
    self.collection = collection
  end

  def as_json(request)
    {
#      collection.model_name.tableize => collection.all.map do |a|
      'stuff' => collection.all.map do |a|
        request.decorate(a).as_json(request.add_path(a.id))
      end,
      :links => [
        *defined_on_collection.map do |relation|
          {:rel => relation, :href => request.add_path(relation).full_path }
        end,
        {:rel => 'self', :href => request.full_path}
      ]
    }
  end

  def rel(relation)
    if defined_on_collection.include? relation
      arity = collection_class.method(relation.to_sym).arity
      Proc.new { |args| collection.__send__ relation.to_sym }.curry(arity)[]
    else
      res = collection.find(relation)
      raise NakedModel::RecordNotFound if res.nil?
      res
    end
  end

  # Create an object on the collection, raising `CreateError` with the message if it fails
  def create(request)
    begin
      created = collection.create!(request.body)
      request.next created, :path => [created.id.to_s]
    rescue ::MongoMapper::DocumentNotValid => e
      raise NakedModel::CreateError.new e.message
    end
  end


  def collection_class
    self.class.collection_class collection
  end

  private
  def defined_on_collection
    (collection_class.public_methods -
     platonic_collection.public_methods).
     reject { |m| m.to_s.match /^(_|original_)/ }.
     map { |m| m.to_s }
  end

  def platonic_collection
    platonic = Class.new
    platonic.send :include, ::MongoMapper::Document
    platonic
  end


end
