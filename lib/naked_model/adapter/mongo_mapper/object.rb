class NakedModel::Adapter::MongoMapper::Object < NakedModel::Adapter
  include MongoMapper

  def handles?(*chain)
    chain.first.class < ::MongoMapper::Document
  end

  def display(obj)
    { obj.class.name.underscore =>
        obj.as_json.merge( :links => [
                              {
                                :rel => 'self',
                                :href => ['.']
                              },
                              *association_names(obj).map { |n| {:rel => n, :href => ['.',n.to_s]}}

                            ] )
    }
  end

  def association_names(obj)
    klass = obj.class
    klass.associations.values.map { |m| m.name }
  end

  def interesting_methods(obj)
    # Columns defined on the object and all associations it has
    klass = obj.class
    methods = (klass.public_instance_methods - platonic_class(klass).public_instance_methods).reject { |m| klass.attribute_method_matchers.any? { |match| match.match(m) } }
    methods = methods.reject { |m| m.to_s.match /^(_|original_)/ }

    methods -= klass.associations_module.public_instance_methods
    methods += association_names(obj).map { |a| a.to_sym }

    methods -= klass.const_get('MongoMapperKeys').public_instance_methods
    methods += klass.keys.values.map { |m| m.name.to_sym }
    methods
  end
end
