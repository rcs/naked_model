class NakedModel::Adapter::ActiveRecord::Object < NakedModel::Adapter
  include NakedModel::Adapter::ActiveRecord

  # We'll handle the object if it's an ActiveRecord::Base inherited object
  def handles?(*chain)
    chain.first.class.ancestors & ar_classes

  end
  #
  # Update the object with parameters in `request.body`, raising `UpdateError` if validation fails
  def update(request)
    begin
      request.target.update_attributes!(request.body)
      request.target
    rescue ::ActiveRecord::RecordInvalid => e
      raise NakedModel::UpdateError.new e.message
    end
  end

  # Interesting methods are ones defined on the object's class, including associations and attributes, but not their helpers
  def interesting_methods(obj)
    # The object's class
    klass = obj.class

    # We care about
    ::Hash[
      # public methods on the class
      (klass.public_instance_methods -
       # that aren't defined on a basic ActiveRecord::Object
       platonic_class(klass).public_instance_methods -
       # and aren't generated attribute methods
       klass.generated_attribute_methods.public_instance_methods +
       # unless they're basic attributes names
       klass.attribute_names.map { |m| m.to_sym } +
       # or association names
       klass.reflect_on_all_associations.map { |m| m.name }
      ).map { |m|
        # and we'll get their method definitions
        [m,obj.method(m)]
      }
    ]
  end

  def display(obj)
      obj.as_json.merge( :links => [
                            {
                              :rel => 'self',
                              :href => ['.']
                            },
                            *obj.class.reflect_on_all_associations.map { |m| {:rel => m.name.to_s, :href => ['.',m.name.to_s]}}

                          ] )
  end
end
