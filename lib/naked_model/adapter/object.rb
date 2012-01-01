# Essentially a stub adapter for Object call passthrough
class NakedModel
  class Adapter
    class Object < NakedModel::Adapter
      # Everything's an object in Ruby, so we handle it
      def handles?(request)
        true
      end

      # Restrict the methods we care about to methods not added to our objects by the language, and return their definitions
      def interesting_methods(obj)
        ::Hash[
          (obj.public_methods - Object.new.public_methods).map { |m| [m,obj.method(m)] }
        ]
      end
    end
  end
end
