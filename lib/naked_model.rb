require 'rack'
require 'multi_json'
require 'addressable/uri'

require_relative 'naked_model/adapter'
require_relative 'naked_model/adapter/array'
require_relative 'naked_model/adapter/hash'

def Array::extract_options!
  last.is_a?(::Hash) ? pop : {}
end

class NakedModel
  class RecordNotFound < StandardError
  end
  class DuplicateError < StandardError
  end
  class UpdateError < StandardError
  end
  class Request
    ATTRIBUTES = [:chain,:request,:body,:status]
    attr_accessor *ATTRIBUTES
    def self.from_env(env)
      request = Rack::Request.new(env)
      self.new(
        :request => request,
        :chain => request.path_info.split('/').reject {|s| s.length == 0 },
        :body => request.body.length > 0 ? MultiJson.decode(request.body) : nil,
        :status => 200
      )
    end
    def initialize(h)
      self.request = h[:request]
      self.chain = h[:chain] || []
      self.body = h[:body] || nil
      self.status = h[:status] || 200
    end

    # Helper method. Use to collapse the first chain elements into the result (default two, for [obj, 'method', others])
    def next(obj,opt = {})
      defaults = {:handled => 2}
      opt = defaults.merge(opt)
      defaults = {
        :request => self.request, 
        :chain => [obj,*self.chain[opt[:handled]..-1]], 
        :body => self.body
      }

      self.class.new defaults.merge(opt)
    end

    def replace(obj)
      self.next(obj,{:handled => 1})
    end

    # Helper methods
    def target
      chain.first
    end

    def method
      chain[1]
    end

    def parameters
      chain[2..-1]
    end
  end
  class Response < Struct.new(:status, :body)
  end

  attr_accessor :adapters

  def initialize(options = {})
    self.adapters = options[:adapters]

    raise ArgumentError.new("Have to give some adapters") unless self.adapters.length
  end

  # Interface for rack, called with the request environment
  def call(env)
    request = Request.from_env(env)

    # TODO special case on / -- all_names
    request = find_namespace(request)

    # Bail if we can't find a root
    return [404, {'Content-Type' => 'text/plain'}, ["No index"]] if request.nil?

    # Push pseuo-path arguments
    # TODO wrap << in request
    case request.request.request_method
    when 'POST'
      request.chain << 'create'
    when 'PUT'
      request.chain << 'update'
    when 'DELETE'
      # TODO traverse back up the chain....
    end


    begin
      # Call the tree and recover from errors
      request = resolve_object request

    rescue RecordNotFound
      return [404, {'Content-Type' => 'text/plain'}, ["Not found: #{request.request.url}"]]
    rescue NoMethodError => e
      raise e
      return [404, {'Content-Type' => 'text/plain'}, ["Not found: #{e.to_s}"]]
    rescue DuplicateError => e
      return [409, {'Content-Type' => 'text/plain'}, [e.message]]
    rescue UpdateError
      return [406, {'Content-Type' => 'text/plain'}, [e.message]]
    end

    body = display(request.target,request)

    body = { :val => body } unless body.is_a? Hash or body.is_a? Array

    # The world's a beautiful place, acknowledge our success
    return [request.status, {'Content-Type' => 'application/json'}, [body.to_json]]
  end

  def find_namespace(request)
    return nil if request.chain.length < 1
    # TODO aesthetics here are ugly. better control structure?
    adapters.each do |adapter|
      model = adapter.find_base(request)
      return model unless model.nil?
    end
    nil
  end

  def all_names(req)
    replace_links({:links => adapters.map { |a| a.all_names }.flatten}, req.request.base_url + req.request.script_name, '')
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

  def invoke_adapters(method,request)
    adapters.each do |adapter|
      if adapter.handles? request.target
        return adapter.__send__(method,request)
      end
    end
    raise NoMethodError
  end
  def display(obj,req)
    adapters.each do |adapter|
      if( adapter.handles? obj )
        return replace_links( adapter.display(obj),req.request.base_url + req.request.script_name,req.request.path_info)
      end
    end
    # Fallback handler....
    obj
  end

  def resolve_object(request)
    return request if request.chain.length < 2

    resolve_object invoke_adapters(:call_proc, request)
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
