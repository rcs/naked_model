require 'rack'
require 'multi_json'
require 'addressable/uri'

require_relative 'naked_model/adapter'
require_relative 'naked_model/adapter/array'
require_relative 'naked_model/adapter/hash'

class NakedModel
  class RecordNotFound < StandardError
  end
  class DuplicateError < StandardError
  end
  class UpdateError < StandardError
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

    if model_name
      # Find the root of our call tree
      model = find_base(model_name,request.env)

      # Bail if we can't find a root
      return [404, {'Content-Type' => 'text/plain'}, ["No index"]] if model.nil?

      begin
        # Call the tree and recover from errors
        obj = resolve_object(model,args)
      rescue RecordNotFound
        return [404, {'Content-Type' => 'text/plain'}, ["Not found: #{args.first}"]]
      rescue NoMethodError => e
        raise e
        return [404, {'Content-Type' => 'text/plain'}, ["Not found: #{e.to_s}"]]
      end

      case request.request_method
      when 'POST'
        begin
          body = display(create(obj,MultiJson.decode(request.body)),request)
          status = 201
        rescue DuplicateError => e
          return [409, {'Content-Type' => 'text/plain'}, [e.message]]
        end
      when 'PUT'
        begin
          body = display(update(obj,MultiJson.decode(request.body)),request)
          status = 200
        rescue UpdateError
          return [406, {'Content-Type' => 'text/plain'}, [e.message]]
        end
      when 'DELETE'
        # TODO traverse back up the chain....
      else
        body = display(obj,request)
        status = 200
      end

    else # model_name
      body = { 'root' => all_names(request) }
      status = 200
    end

    body = { :val => body } unless body.is_a? Hash or body.is_a? Array

    # The world's a beautiful place, acknowledge our success
    return [status, {'Content-Type' => 'application/json'}, [body.to_json]]
  end

  def find_base(name,env)
    return nil if name.nil?
    # TODO aesthetics here are ugly. better control structure?
    adapters.each do |adapter|
      model = adapter.find_base(name,env)
      return model unless model.nil?
    end
    nil
  end

  def all_names(req)
    replace_links({:links => adapters.map { |a| a.all_names }.flatten}, req.base_url + req.script_name, '')
  end

  def replace_links(obj,root,relative)

    if obj.is_a? Array
      obj.each { |e| replace_links(e,root,relative) }
    elsif obj.is_a? Hash
      obj.each do |k,v|
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
  end

  def invoke_adapters
    # TODO stub
  end
  def display(obj,req)
    adapters.each do |adapter|
      if( adapter.handles? obj )
        return replace_links( adapter.display(obj),req.base_url + req.script_name,req.path_info)
      end
    end
    # Fallback handler....
    obj
  end

  def create(obj,req)
    adapters.each do |adapter|
      if( adapter.handles? obj )
        return adapter.create(obj,req)
      end
    end
    raise NoMethodError
  end

  def update(obj,req)
    adapters.each do |adapter|
      if( adapter.handles? obj )
        return adapter.update(obj,req)
      end
    end
    raise NoMethodError
  end

  def resolve_object(obj, chain)
    return obj if chain.length < 1

    res = nil
    adapters.each do |adapter|
      if( adapter.handles? obj )
        debug("Calling #{adapter} with #{chain}")
        res = adapter.call_proc(obj,*chain)
        break
      end
    end

    # Nothing handled it
    raise NoMethodError if res.nil?

    # Stuff remaining, get 'er done
    resolve_object(res[:res],res[:remaining])
  end

  # Take a Rack::Request and turn it into a method name and ruby-style argument list
  def extract_arguments(req)
    method, *fixed = req.path_info.split('/').reject {|s| s.length == 0 }

    #if req.params.length > 0 then
    #  fixed.push req.params
    #end

    [method,*fixed]
  end

  # Helper method for my debugging
  def log(*stuff)
    $stderr.puts stuff
  end

  alias :debug :log

  def self.boring_instance
    self.new :adapters => [
        NakedModel::Adapter::Array.new,
        NakedModel::Adapter::Hash.new
      ]
  end
end
