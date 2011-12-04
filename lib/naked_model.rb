require 'rack'
require 'multi_json'
require 'addressable/uri'

require_relative 'naked_model/adapter'
require_relative 'naked_model/adapter/array'
require_relative 'naked_model/adapter/hash'

class NakedModel
  class RecordNotFound < StandardError
  end

  attr_accessor :adapters

  def initialize(options = {})
    self.adapters = options[:adapters]

    raise ArgumentError.new("Have to give some adapters") unless self.adapters.length
  end

  # Interface for rack, called with the request environment
  def call(env)
    request = Rack::Request.new(env)
    url = Addressable::URI.parse(request.url)

    # Set up the method and parameters to call
    model_name, *args = extract_arguments(request)

    begin
      # Find the root of our call tree
      model = find_base(model_name)

      # Bail if we can't find a root
      return [404, {'Content-Type' => 'text/plain'}, ["No index"]] if model.nil?

      # Call the tree and recover from errors
      body = display(call_methods(model,args),request)

      body = { :val => body } unless body.is_a? Hash or body.is_a? Array

    rescue RecordNotFound
      return [404, {'Content-Type' => 'text/plain'}, ["Not found: #{args.first}"]]
    rescue NoMethodError => e
      raise e
      return [404, {'Content-Type' => 'text/plain'}, ["Not found: #{e.to_s}"]]
    end

    # The world's a beautiful place, acknowledge our success
    return [200, {'Content-Type' => 'application/json'}, [body.to_json]]
  end

  def find_base(name)
    return nil if name.nil?
    # TODO aesthetics here are ugly. better control structure?
    adapters.each do |adapter|
      model = adapter.find_base(name)
      return model unless model.nil?
    end
    nil
  end

  def replace_links(hsh,root,relative)
    hsh.each do |k,v|
      if k == :links
        v.select { |v| v.is_a? ::Hash }.each do |ldi|
          ldi[:href] = [case ldi[:href].first
           when '.'
             root + relative
           when '/'
             root
           else
             ldi[:href].first
           end, *Array(ldi[:href][1..-1])].join '/'
        end
      else
        replace_links(v,root,relative) if v.is_a? ::Hash
        v.each { |e| replace_links(e,root,relative) } if v.is_a? ::Array
      end
    end
  end

  def invoke_adapters
    # TODO stub
  end
  def display(obj,req)
    adapters.each do |adapter|
      if( adapter.handles? obj )
        puts "Displaying #{obj} with #{adapter}"
        return replace_links( adapter.display(obj),req.base_url + req.script_name,req.path_info)
      end
    end
    obj
  end

  def call_methods(obj, chain)
    return obj if chain.length < 1

    res = nil
    adapters.each do |adapter|
      if( adapter.handles? obj )
        res = adapter.call_proc(obj,*chain)
        break
      end
    end

    # Nothing handled it
    raise NoMethodError if res.nil?

    # Stuff remaining, get 'er done
    call_methods(res[:res],res[:remaining])
  end

  # Take a Rack::Request and turn it into a method name and ruby-style argument list
  def extract_arguments(req)
    method, *fixed = req.path_info.split('/').reject {|s| s.length == 0 }

    if req.params.length > 0 then
      fixed.push req.params
    end

    [method,*fixed]
  end

  # Helper method for my debugging
  def log(*stuff)
    $stderr.puts stuff
  end

  def self.boring_instance
    self.new :adapters => [
        NakedModel::Adapter::Array.new,
        NakedModel::Adapter::Hash.new
      ]
  end
end
