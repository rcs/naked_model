class NakedModel::Decorator::MongoMapper::Object
  attr_accessor :obj

  def initialize(obj)
    self.obj = obj
  end

  def as_json(request)
    links = relations.map { |relation|
      {:rel => relation, :href => request.add_path(relation).full_path}
    }
    links << { :rel => 'self', :href => request.full_path }
    obj.as_json.merge :links => links
  end

  def update(request)
    begin
      obj.update_attributes!(request.body)
      obj
    rescue ::MongoMapper::DocumentNotValid => e
      raise NakedModel::UpdateError.new e.message
    end
  end

  def rel(relation)
    raise NakedModel::RecordNotFound unless relations.any? { |l| l.include? relation }

    obj.method(relation.to_sym).to_proc.curry[]
  end

  private
  # Relationships this object has
  def relations
    [defined_on_object,associations].flatten
  end

  # Associations on the object
  def associations
    obj.associations.values.map { |a| a.name.to_s }
  end

  def defined_on_object
    methods = obj.public_methods
    # Base MongoMapper methods
    methods -= platonic_collection.public_instance_methods
    # Document keys and associated methods
    methods -= obj.class.const_get('MongoMapperKeys').public_instance_methods
    # Association helpers
    methods -= obj.class.associations_module.public_instance_methods
    # Alias leftovers
    methods.reject! { |m| m =~ /^_/ }

    methods.map { |m| m.to_s }
  end

  def platonic_collection
    klass = Class.new
    klass.send :include, ::MongoMapper::Document
  end

  def interesting_fields(obj)
    # Attributes of this object that aren't prefixed and
    obj.attributes.keys.reject { |f| f.to_s.match /^_/ } -
      # that aren't "utility" fields for storing associations (:in is mongo_mapper speak for a field containing ids
      klass.associations.values { |v| v.options[:in] }.reject { |i| i.nil? }.map { |i| i.to_s }
  end

end
