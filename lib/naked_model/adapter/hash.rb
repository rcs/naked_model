# Basic adapter for `Hash` objects
class NakedModel
  class Adapter
    class Hash < NakedModel::Adapter

      # `Hash.new` takes a hash to wrap for namespace purposes
      def initialize(h)
        raise ArgumentError unless h.is_a? ::Hash
        @names = h
      end

      # On `update`, we merge the request body into the target
      def update(request)
        request.target.merge! request.body
      end

      def all_names
        @names.keys.map { |k|
          { :rel => k.to_s, :href => ['.', k.to_s] }
        }
      end

      # On `create`, we set the `body.name` key of the `target` to `body[name]`
      def create(request)
        # If the key already exists, bail
        name = request.body['name']
        raise CreateError if request.target.has_key? name

        request.target[name] = request.body[name]

        request.next request.target[name], :path => [name]
      end

      def find_base(request)
        # If the hash taken on initialization matches the `target`, that has becomes our new `target`
        return request.replace(@names[request.target]) if @names.has_key? request.target
        return nil
      end

      # Handle `Hash` objects
      def handles?(*chain)
        chain.first.is_a? ::Hash
      end

      #  Call the base `Adapter` call_proc, trying to find the `method` as a key in the hash if not handled
      def call_proc(request)
        begin
          super
        rescue NoMethodError => e
          raise NakedModel::RecordNotFound if not request.target.has_key? request.method

          return request.next request.target[request.method]
        end
      end
    end
  end
end
