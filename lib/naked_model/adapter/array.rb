class NakedModel
  class Adapter
    class Array < NakedModel::Adapter
      def handles?(*chain)
        t = chain.first
        t.is_a? Array
      end
      def interesting_methods(obj)
        try_methods = [:first, :last]

        methods = {}
        try_methods.select do |m|
          obj.respond_to? m
        end.each do |m|
          methods[m] = { :params => [[]] }
        end

        methods
      end

      def call_proc(request)
        begin
          super
        rescue NoMethodError => e
          if is_num? request.method
            request.next request.target[request.method]
          else
            raise e
          end
        end
      end
    end
  end
end
