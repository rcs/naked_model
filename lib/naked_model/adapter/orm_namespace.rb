class NakedModel
  module Adapter::OrmNamespace
    attr_accessor :orm_classes
    def find_base(request)
      if orm_class? request.target.classify
        thing =  request.replace Kernel.const_get(request.target.classify)
        return thing
      end
      return nil
    end

    def orm_class?(klass)
      class_exists? klass and orm_classes.any? { |orm| Kernel.const_get(klass).ancestors.include? orm }
    end

    def class_exists?(class_name)
      klass = Module.const_get(class_name)
      return klass.is_a?(Class)
    rescue NameError
      return false
    end
  end
end
