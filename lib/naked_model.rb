require 'rack'
require 'multi_json'

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

    if request.target.nil?
      return [200, {'Content-Type' => 'application/json'}, [all_names(request).to_json]]
    end

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
      return [404, {'Content-Type' => 'text/plain'}, ["Not found: #{e.to_s}"]]
    rescue CreateError => e
      return [409, {'Content-Type' => 'text/plain'}, [e.message]]
    rescue UpdateError => e
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
    thing = replace_links({ :links => adapters.map { |a| a.all_names }.flatten}, req)
  end


  # Find obj[:links] elements and change their name paths to hrefs
  def replace_links(obj,request)

    # Call this function  for each element if obj is an Array
    return obj.map { |e| replace_links(e,request); e } if obj.is_a? Array

    # Current scope is set to the root + relative url (SCRIPT_NAME + PATH_INFO) to start
    current_scope = [request.request.base_url+request.request.script_name,*request.path].join('/')

    if links = obj[:links]
      # Deal with res => :self first, store its href as "current_scope"
      if self_ref = links.select { |k| k[:rel] == 'self' }
        self_ref.each do |r|
          # Turn the href array into a url
          r[:href] = rel_to_url(r[:href],current_scope)
          current_scope = r[:href]
        end
      end

      # rel_to_url each element except the self we did before
      links.select { |k| k[:rel] != 'self' }.each do |r|
        r[:href] = rel_to_url(r[:href],current_scope)
      end

      obj[:links] = links
    end
    obj
  end

  # Turn an array of URL fragments into a URL string, replacing "." with the context
  # TODO better calling conventions?
  def rel_to_url(fragments,context)
    fragments.each_with_index.map { |v,i|
      if i == 0 and v == '.'
        context
      else
        v
      end
    }.join '/'
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
        return replace_links( adapter.display(obj),req)
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

end
