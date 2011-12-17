class NakedModel::Adapter::ActiveRecord::Object < NakedModel::Adapter
  include NakedModel::Adapter::ActiveRecord

  def handles?(*chain)
    chain.first.class < ::ActiveRecord::Base
  end

  def interesting_methods(obj)
    # Columns defined on the object and all associations it has
    klass = obj.class
    methods = (klass.public_instance_methods - platonic_class(klass).public_instance_methods - klass.generated_attribute_methods.public_instance_methods)
    methods += klass.attribute_names.map { |m| m.to_sym }
    methods += klass.reflect_on_all_associations.map { |m| m.name }
    methods
  end
end
