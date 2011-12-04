class NakedRecord
  class Adapter
    class Array < NakedRecord::Adapter
      def handles?(*chain)
        t = chain.first
        t.is_a? Array
      end
      def callable_methods(obj)
        try_methods = [:first, :last,:[]]

        methods = {}
        try_methods.select do |m|
          obj.respond_to? m
        end.each do |m|
          methods[m] = { :params => [[]] }
        end

        methods
      end

      def call_proc(*chain)
        target, method, *remaining = chain

        if is_num? method
          method = :[]
        end

        return nil unless callable_methods(target).include? method.to_sym or (is_num? method and callable_methods(target).include? :[])

        if callable_methods(target).include? method.to_sym
          {
            :res => target.send(method),
            :remaining => remaining
          }
        elsif is_num? method
          {
            :res => target.send(:[],method),
            :remaining => remaining
          }
        end
      end
    end
  end
end
