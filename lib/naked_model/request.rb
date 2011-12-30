### NakedModel::Request
# A `NakedModel::Request` consists mainly of four things:
# *   `chain`: holds the remaining relationships to be processed ( '/one/two/three' => ['one','two','three'] )
# *   `request`: the original Rack request
# *   `body`: the body to be passed forward along the chain processing
# *   `status`: the processing status of the chain, used for constructing the eventual response
class NakedModel::Request
  ATTRIBUTES = [:chain,:request,:body,:status]
  attr_accessor *ATTRIBUTES

  # Create a new `Request` from the environment from `Rack`
  def self.from_env(env)
    request = Rack::Request.new(env)
    # Decode the body from JSON
    body = begin
             MultiJson.decode(request.body)
           rescue MultiJson::DecodeError
             nil
           end
    self.new(
      :request => request,
      # Split the path_info into the chain that will be iterated on
      :chain => request.path_info.split('/').reject {|s| s.length == 0 },
      :body => body,
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
  # Return a new request object, collapsing the chain of `this` object into the new `target`
  # Defaults to the first two chain elements, but accepts an options hash with `:handled` set to the number of parameters to collapse
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

  # Helper method to create a new request object, only replacing the target
  def replace(obj)
    self.next(obj,{:handled => 1})
  end

  # Helper methods

  # The current request target
  def target
    chain.first
  end

  # Commonly the method to call on the target
  def method
    chain[1]
  end

  # The remaining chain elements past the target and method
  def parameters
    chain[2..-1]
  end
end
