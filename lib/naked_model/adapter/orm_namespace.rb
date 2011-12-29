# Helper methods for things that are ORM collections
class NakedModel
  module Adapter::OrmNamespace
    # `:orm_classes` should be set on the classes that include this; a list of classes that class will handle
    attr_accessor :orm_classes

    # Turn the base of a request object into the Collection class
    def find_base(request)
      # Is this a class we handle?
      return nil unless orm_class? request.target.classify

      # Return the new request with the collection class as the target
      request.replace Kernel.const_get(request.target.classify)
    end

    # Check whether this class exists an is handled by us
    def orm_class?(klass)
      class_exists? klass and orm_classes.any? { |orm| Kernel.const_get(klass).ancestors.include? orm }
    end

    # Helper method to divine whether a string maps to a defined class
    def class_exists?(class_name)
      klass = Module.const_get(class_name)
      return klass.is_a?(Class)
    rescue NameError
      return false
    end
  end
end
