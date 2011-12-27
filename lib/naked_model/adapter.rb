require 'addressable/uri'
require File.dirname(__FILE__) + '/../naked_model'
class NakedModel
  class Adapter
    def call_proc(*chain)
      target,method,*remaining = chain

      interesting = interesting_methods(target);
      if method_def = interesting_methods(target)[method.to_sym]
        required = method_def.
          parameters.
          select { |p| p[0] == :req }.
          length

        raise ArgumentError, "Missing arguments" if required > remaining.length
        parameters = remaining[0..required-1]
        left_over = remaining[required..-1]
        puts "p: #{parameters} lo: #{left_over}"

        {:res => target.__send__(method.to_sym, *parameters), :remaining => left_over}
      else
        raise NoMethodError
      end
    end

    def display(obj)
      if obj.respond_to? :as_json
        obj = obj.as_json
      end

      obj.merge :links => [ { :rel => 'self', :href => ['.'] } ]
    end

    # Helper, for mapping 1 -> find(1) or [1]
    def is_num?(str)
      Integer(str)
    rescue
      false
    else
      true
    end

    def find_base(name,env)
      nil
    end

    def all_names
      []
    end

    def handles?
      nil
    end

  end
end
