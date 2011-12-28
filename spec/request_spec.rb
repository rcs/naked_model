require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'naked_model'
require 'rack'

describe NakedModel::Request do
  before :all do
    @env = {
      'rack.input' => StringIO.new(''),
      'rack.errors' => $stderr,
      'CONTENT_LENGTH' => 0
    }
  end
  before :each do
    @rr = Rack::Request.new(@env)
  end

  it "instantiates from environment" do
    NakedModel::Request.from_env(@env)
  end

  it "instantiates from hash" do
    NakedModel::Request.new :request => @rr, :chain => [], :body => {}
  end

  it "reduces the chain" do
    r = NakedModel::Request.new :request => @rr, :chain => ['a','b','c'], :body => {}
    req = r.next('a->b')
    req.chain.should == ['a->b','c']
  end
end
