class NakedModel::Adapter::MongoMapper::Object < NakedModel::Adapter
  include MongoMapper

  def handles?(*chain)
    chain.first.class < ::MongoMapper::Document
  end

  def update(request)
    begin
      request.target.update_attributes(request.body)
    rescue ::MongoMapper::DocumentNotValid => e
      raise NakedModel::UpdateError.new e.message
    end
  end

  def display(obj)
    #{ obj.class.name.underscore =>
        obj.as_json.select { |k,v| interesting_fields(obj).include?(k.to_s) }.merge( :links => [
                              {
                                :rel => 'self',
                                :href => ['.']
                              },
                              *association_names(obj).map { |n| {:rel => n, :href => ['.',n.to_s]}}

                            ] )
    #}
  end

  def interesting_fields(obj)
    klass = obj.class
    klass.column_names.reject{ |f| f.to_s.match /^_/ } - klass.associations.map { |k,v| v.options[:in] }.reject { |i| i.nil? }.map { |i| i.to_s }
  end

  def interesting_methods(obj)
    # Columns defined on the object and all associations it has
    klass = obj.class

    methods = defined_on_class(obj.class) +
      association_names(obj).map { |a| a.to_sym } + # Associations
      klass.keys.values.map { |m| m.name.to_sym }   # Fields


    ::Hash[methods.map { |m| [m,obj.method(m)] }]
  end

  def defined_on_class(klass)
    (klass.public_instance_methods -                               # Class responds to
      platonic_class(klass).public_instance_methods -              # A class with the same ancestry responds to
      klass.associations_module.public_instance_methods -          # Association helpers
      klass.const_get('MongoMapperKeys').public_instance_methods). # Field helpers
      reject { |m| klass.attribute_method_matchers.any? { |match| match.match(m) } }. # Generated for attributes defined on the class
      reject { |m| m.to_s.match /^(_|original_)/ }                 # Methods not intended for public consumption, or moved out of the way for aliasing
  end
end
