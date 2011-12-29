class NakedModel
  class Adapter
    class Object < NakedModel::Adapter
      def handles?(*chain)
        true
      end

      def interesting_methods(obj)
        ::Hash[
          (obj.public_methods - Object.new.public_methods).map { |m| [m,obj.method(m)] }
        ]
      end
    end
  end
end
