require 'rack'
require 'multi_json'


class NakedModel
  require_relative 'naked_model/request'

  module Decorator; end
  # Define custom error classes for standard-ish interfaces
  class RecordNotFound < StandardError
  end
  class CreateError < StandardError
  end
  class UpdateError < StandardError
  end

  attr_accessor :namespace

  # 
  # `NakedModel.new` takes an options hash, which currently cares about one thing:
  # *   `:adapters` specifies an array of adapters to route requests through
  #
  def initialize(namespace)
    self.namespace = namespace
  end

  # `call` is the Interface for rack, called with the request environment
  def call(env)
    # Create a NakedModel::Request from the environment
    request = Request.from_env(env,namespace)

    # Push pseuo-path arguments, turning http methods into special case methods to call on adapters
    # TODO wrap << in request
#    case request.request.request_method
#    when 'POST'
#      request.chain << 'create'
#    when 'PUT'
#      request.chain << 'update'
#    when 'DELETE'
#      # TODO traverse back up the chain....
#    end



    # Resolve the request to its end, catching errors thrown during the resolution
    begin
      resolved = request.chain.reduce(namespace) do |progress,fragment| 
        $stderr.puts "Relating #{fragment} on #{progress}"
        successor = progress.rel(fragment)
        $stderr.puts "Successor is #{successor}"
        request.decorate successor
      end

      $stderr.puts "resolved: #{resolved}"

    rescue NakedModel::RecordNotFound
      return [404, {'Content-Type' => 'text/plain'}, ["Not found: #{request.request.url}"]]
    rescue NakedModel::CreateError => e
      return [409, {'Content-Type' => 'text/plain'}, [e.message]]
    rescue NakedModel::UpdateError => e
      return [406, {'Content-Type' => 'text/plain'}, [e.message]]
    end

    # Serialize the final object for returning to the client
    body = resolved.as_json request

    # The world's a beautiful place, acknowledge our success
    return [200, {'Content-Type' => 'application/json'}, [body.to_json]]
  end
end
