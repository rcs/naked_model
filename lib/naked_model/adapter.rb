require 'addressable/uri'
require File.dirname(__FILE__) + '/../naked_model'
class NakedModel
  class Adapter
    def call_proc(request)

      if method_def = interesting_methods(request.target)[request.method.to_sym]
        required = method_def.
          parameters.
          select { |p| p[0] == :req }.
          length

        raise ArgumentError, "Missing arguments" if required > request.parameters.length
        parameters = request.parameters[0..required-1]

        request.next request.target.__send__(request.method.to_sym, *parameters), :handled => required

      elsif request.method == 'create'
        request.next create(request), :status => 201
      elsif request.method == 'update'
        request.next update(request)
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

    def find_base(request)
      nil
    end

    def all_names
      []
    end

    def interesting_methods(obj)
      {}
    end

    def update(request)
      raise NotImplementedError
    end

    def create(request)
      raise NotImplementedError
    end

    def handles?
      nil
    end

  end
end
