class NakedModel
  class Adapter
    class Hash < NakedModel::Adapter
      def initialize(h)
        raise ArgumentError unless h.is_a? ::Hash
        @names = h
      end

      def update(request)
        request.target.merge! request.body
      end

      def create(request)
        if request.target.has_key? request.body['name']
          raise DuplicateError
        else
          request.target[request.body['name']] = request.body[request.body['name']]
        end
      end

      def find_base(request)
        return request.replace(@names[request.chain.first]) if @names.has_key? request.chain.first
        return nil
      end

      def handles?(*chain)
        chain.first.is_a? ::Hash
      end

      def call_proc(request)
        begin
          super
        rescue NoMethodError => e
          if request.target.has_key? request.method
            return request.next request.target[request.method]
          else
            raise NakedModel::RecordNotFound
          end
        end
      end
    end
  end
end
