require 'rack'
require 'multi_json'
require 'addressable/uri'

require_relative 'naked_model/adapter'
require_relative 'naked_model/request'
require_relative 'naked_model/adapter/array'
require_relative 'naked_model/adapter/hash'

class NakedModel
  # Define custom error classes for standard-ish interfaces
  class RecordNotFound < StandardError
  end
  class CreateError < StandardError
  end
  class UpdateError < StandardError
  end

  attr_accessor :adapters

  #### Public Interface
  # 
  # `NakedModel.new` takes an options hash, which currently cares about one thing:
  # *   `:adapters` specifies an array of adapters to route requests through
  #
  def initialize(options = {})
    self.adapters = options[:adapters]

    raise ArgumentError.new("Have to give some adapters") unless self.adapters.length
  end

  # `call` is the Interface for rack, called with the request environment
  def call(env)
    # Create a NakedModel::Request from the environment
    request = Request.from_env(env)

    # Find the base object. Turns a string into an object that subsequent resolving will be done against
    # TODO special case on / -- all_names
    request = find_namespace(request)

    # Bail if we can't find a root
    return [404, {'Content-Type' => 'text/plain'}, ["No index"]] if request.nil?

    # Push pseuo-path arguments, turning http methods into special case methods to call on adapters
    # TODO wrap << in request
    case request.request.request_method
    when 'POST'
      request.chain << 'create'
    when 'PUT'
      request.chain << 'update'
    when 'DELETE'
      # TODO traverse back up the chain....
    end


    # Resolve the request to its end, catching errors thrown during the resolution
    begin
      request = resolve_object request

    rescue RecordNotFound
      return [404, {'Content-Type' => 'text/plain'}, ["Not found: #{request.request.url}"]]
    rescue NoMethodError => e
      raise e
      return [404, {'Content-Type' => 'text/plain'}, ["Not found: #{e.to_s}"]]
    rescue CreateError => e
      return [409, {'Content-Type' => 'text/plain'}, [e.message]]
    rescue UpdateError
      return [406, {'Content-Type' => 'text/plain'}, [e.message]]
    end

    # Serialize the final object for returning to the client
    body = display(request.target,request)

    # Wrap single valued responses in a hash for JSON encoding
    body = { :val => body } unless body.is_a? Hash or body.is_a? Array

    # The world's a beautiful place, acknowledge our success
    return [request.status, {'Content-Type' => 'application/json'}, [body.to_json]]
  end

  def find_namespace(request)
    # We don't have anything to work with
    return nil if request.chain.length < 1

    # TODO aesthetics here are ugly. better control structure?
    # Query adapters to find one that handles our base
    adapters.each do |adapter|
      model = adapter.find_base(request)
      return model unless model.nil?
    end
    nil
  end

  # Query all adapters for their names to give in an index, setting the root url to our root
  def all_names(req)
    replace_links({:links => adapters.map { |a| a.all_names }.flatten}, req.request.base_url + req.request.script_name, '')
  end


  # Find obj[:links] elements and change their name paths to hrefs
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


  # Helper method for a common control structure
  # Call `method` on the first adapter that handles our `request.target`, raising `NoMethodError` if none do
  def invoke_adapters(method,request)
    adapters.each do |adapter|
      if adapter.handles? request.target
        return adapter.__send__(method,request)
      end
    end
    raise NoMethodError
  end

  # Invoke the adapter that is willing to display our request, replacing links on the result
  def display(obj,req)
    adapters.each do |adapter|
      if( adapter.handles? obj )
        return replace_links( adapter.display(obj),req.request.base_url + req.request.script_name,req.request.path_info)
      end
    end
    # Fallback handler....
    obj
  end

  # Take a request object and repeatedly give it to adapters until it's resolved to a single value
  def resolve_object(request)
    # If we have a single value, we're done
    return request if request.chain.length < 2
    resolve_object invoke_adapters(:call_proc, request)
  end

  # Helper method for debugging
  def log(*stuff)
    $stderr.puts stuff
  end

  alias :debug :log

end
