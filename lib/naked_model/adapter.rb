require 'addressable/uri'
require File.dirname(__FILE__) + '/../naked_model'
class NakedModel
  class Adapter
    def call_proc(*chain)
      target,method,*remaining = chain

      if interesting_methods(target).include? method.to_sym
        {:res => target.__send__(method), :remaining => remaining}
      else
        raise NoMethodError
      end
    end

    def display(obj)
      if obj.respond_to? :as_json
        obj = obj.as_json
      end
      if obj.respond_to? :merge
        obj.merge :links => [ { :rel => 'self', :href => ['.'] } ]
      else
        obj
      end
    end

    def short_fields
      %w{title name id}
    end

    def build_links(obj,url)
      { :self => url.to_s }
    end

    # Helper, for mapping 1 -> find(1) or [1]
    def is_num?(str)
      Integer(str)
    rescue
      false
    else
      true
    end

    def find_base(name)
      nil
    end

    def all_names
      []
    end

  end
end
