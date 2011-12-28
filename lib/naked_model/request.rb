class NakedModel::Request
  ATTRIBUTES = [:chain,:request,:body,:status]
  attr_accessor *ATTRIBUTES
  def self.from_env(env)
    request = Rack::Request.new(env)
    body = begin
             MultiJson.decode(request.body)
           rescue MultiJson::DecodeError
             nil
           end
    self.new(
      :request => request,
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
