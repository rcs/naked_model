class NakedModel
  class Adapter
    class Hash < NakedModel::Adapter
      def initialize(h)
        raise ArgumentError unless h.is_a? ::Hash
        @names = h
      end
      def find_base(name,env)
        return @names[name] if @names.has_key? name
        return nil
      end
      def handles?(*chain)
        chain.first.is_a? ::Hash
      end
      def call_proc(*chain)
        obj, name, *remaining = chain

        if obj.has_key? name
          return {
            :res => obj[name],
            :remaining => remaining
          }
        else
          raise NakedModel::RecordNotFound
        end
      end
    end
  end
end