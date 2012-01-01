# Adapter for Array objects
class NakedModel
  class Adapter
    class Array < NakedModel::Adapter
      # Handle only Array objects
      def handles?(request)
        request.target.is_a? ::Array
      end

      # Return methods that can be called on the array, with their definitions
      # `:first` and `:last` seemed safe
      def interesting_methods(obj)
        ::Hash[
          [:first,:last].map { |m| [m,obj.method(m)] }
        ]
      end

      # Call the base `Adapter` call_proc, falling back to trying to return an array element if it wasn't handled
      def call_proc(request)
        begin
          super
        rescue NoMethodError => e
          # Re-raise the error if `method` doesn't look like an array index
          raise e if not is_num? request.method

          ret = request.target[request.method]

          # if the array element didn't exist, wrap for NM semantics
          raise RecordNotFound if ret.nil?

          request.next ret
        end
      end
    end
  end
end

