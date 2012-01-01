require File.dirname(__FILE__) + '/../naked_model'

# The basic `Adapter` class, which can be inherited from for specialized adapters
class NakedModel
  class Adapter

    # Important methods to override in children:
    # * `update`: called with the request when an update is performed
    # * `create`: called with the request when an update is performed
    # * `all_names`: queried to generate "index" pages
    # * `display`: called to translate the target to something appropriate to serialize
    # * `handles`: called to determine whether this adapter will handle the request
    # * `interesting_methods`: used by the base `call_proc` to determine whether a method is available for calling
    # * `find_base`: called to see whether the string coming in matches something your adapter cares about

    # `call_proc` is the workhorse method, taking a request returning a request one step closer to completion
    def call_proc(request)

      # Check if the request we're trying to make is included in the methods we should be calling
      if method_def = interesting_methods(request.target)[request.method.to_sym]
        # Divine the number of required parameters for that method
        required = method_def.
          parameters.
          select { |p| p[0] == :req }.
          length

        # Raise an error if we can't satisfy the required arguments for the method
        raise ArgumentError, "Missing arguments" if required > request.parameters.length

        # Pull the parameters we'll be passing out of the request
        parameters = required > 0 ? request.parameters[0..required-1] : []

        # Return a new request, with its target set to the result of the method call and with the parameters we used removed
        request.next request.target.__send__(request.method.to_sym, *parameters), :handled => required + 2 # (target,method,params)
      elsif request.method == 'create'
        # Specal method request to proxy 'create' to the adapter and set the status for RESTish goodness
        create(request).tap { |o| o.status = 201 }
      elsif request.method == 'update'
        # Special method call to proxy 'update' to the adapter
        request.next update(request)
      else
        # We couldn't find it in the methods we care about, or the special method adapters
        raise NoMethodError
      end
    end

    # Prepare the object for display
    def display(obj)
      if obj.respond_to? :as_json
        obj = obj.as_json
      end

      # Add in links for relationships of this object
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

    # Base adapter doesn't return for any namespaces
    def find_base(request)
      nil
    end

    # Base adapter doesn't have any namespaces to resolve
    def all_names
      []
    end

    # Base adapter doesn't respnd to any methods 
    def interesting_methods(obj)
      {}
    end

    # Base adapter doesn't handle anything
    def handles?(request)
      nil
    end

  end
end
