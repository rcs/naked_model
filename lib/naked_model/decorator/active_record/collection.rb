class NakedModel::Decorator::ActiveRecord::Collection
  attr_accessor :collection
  def initialize(collection)
    self.collection = collection
  end

  def as_json(request)
    {
      'TODO' => collection.all.map do |a|
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
      # Try to find this as an id in the collection
      begin
        collection.find(relation)
      rescue ::ActiveRecord::RecordNotFound
        raise NakedModel::RecordNotFound.new(relation)
      end
    end
  end

  def create(request)
    begin
      created = collection.create!(request.body)
      request.next created, :path => [created.id.to_s]
    rescue ::ActiveRecord::RecordInvalid => e
      raise NakedModel::CreateError.new e
    end
  end

  def self.collection_class obj
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

    if klass <  ActiveRecord::Base
      klass
    else
      nil
    end
  end

  private
  def collection_class
    self.class.collection_class collection
  end

  def defined_on_collection
    (collection_class.public_methods -
     platonic_collection.public_methods).
     reject { |m| m.to_s.match /^(_|original_)/ }.
     map { |m| m.to_s }
  end

  def platonic_collection
    platonic = Class.new(::ActiveRecord::Base)
    # Build associations
    collection.reflect_on_all_associations.each do |assoc|
      builder = "::ActiveRecord::Associations::Builder::" +  assoc.macro.to_s.classify
      builder.constantize.send(:build, platonic, assoc.name,assoc.options)
    end
    # Build aggregations
    collection.reflect_on_all_aggregations.each do |agg|
      builder = "::ActiveRecord::Aggregations::Builder::" +  agg.macro.to_s.classify
      builder.constantize.send(:build, platonic, agg.name,agg.options)
    end
    platonic
  end
end
