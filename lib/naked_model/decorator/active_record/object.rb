class NakedModel::Decorator::ActiveRecord::Object
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
    rescue ::ActiveRecord::RecordInvalid => e
      raise NakedModel::UpdateError.new e.message
    end
  end

  def rel(relation)
    if relations.any? { |l| l.include? relation }
      obj.method(relation.to_sym).to_proc.curry[]
    else
      raise NakedModel::RecordNotFound.new(relation)
    end
  end

  private
  def relations
    [defined_on_object,associations,aggregations].flatten
  end
  def associations
    obj.class.reflect_on_all_associations.map { |a| a.name.to_s }
  end
  def aggregations
    obj.class.reflect_on_all_aggregations.map { |a| a.name.to_s }
  end
  def defined_on_object
    methods = obj.public_methods.map { |m| m.to_s }
    methods -= platonic_collection.public_instance_methods.map { |m| m.to_s }
    methods -= generated_attribute_methods
    methods.reject! { |m| m =~ /^_/ }
  end

  # List all *possible* generated attribute methods for the object
  def generated_attribute_methods
    obj.attributes.keys.map { |attr|
      obj.class.attribute_method_matchers.map { |match|
        match.method_name attr
      }
    }.flatten
  end
  # Generate a class corresponding to a collection of objs
  def platonic_collection
    platonic = Class.new(::ActiveRecord::Base)
    # Build associations
    obj.class.reflect_on_all_associations.each do |assoc|
      builder = "::ActiveRecord::Associations::Builder::" +  assoc.macro.to_s.classify
      builder.constantize.send(:build, platonic, assoc.name,assoc.options)
    end
    # Build aggregations
    obj.class.reflect_on_all_aggregations.each do |agg|
      builder = "::ActiveRecord::Aggregations::Builder::" +  agg.macro.to_s.classify
      builder.constantize.send(:build, platonic, agg.name,agg.options)
    end
    platonic
  end
end
