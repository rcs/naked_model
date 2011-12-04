class NakedRecord
  module Adapter::OrmNamespace
    attr_accessor :orm_classes
    def find_base(name)
      return nil unless orm_class? name.classify
      Kernel.const_get(name.classify)
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
