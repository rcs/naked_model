require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'naked_model'
require 'naked_model/adapter/object'

class SimpleObject
  attr_accessor :color

  def initialize
    self.color = 'red'
  end

  def zero_arg
    'simple'
  end

  def one_arg(arg)
    "arg: #{arg}"
  end

  def two_arg(one,two)
    [two,one]
  end

  def hash_arg(h)
    h.keys
  end

  def one_hash_arg(arg,h)
    arg.to_s + h.map { |k,v| "#{k}: #{v}" }.join(" ")
  end

  def rest_arg(*args)
    args.join("<->")
  end

  private
  def imprivate
  end

end

describe NakedModel::Adapter::Object do
  before :each do
    @adapter = NakedModel::Adapter::Object.new
    @s_o = SimpleObject.new
  end

  it "handles objects" do
    @adapter.handles?(req_from_chain(@s_o)).should be_true
  end

  it "handles accessors" do
    @adapter.call_proc(req_from_chain(@s_o, 'color')).target.should == 'red'
  end
  it "handles simple methods" do
    @adapter.call_proc(req_from_chain(@s_o, 'zero_arg')).target.should == 'simple'
  end

  it "handles one arg methods" do
    @adapter.call_proc(req_from_chain(@s_o, 'one_arg', 'argument')).target.should == 'arg: argument'
  end

  it "handles two arg methods" do
    @adapter.call_proc(req_from_chain(@s_o, 'two_arg', 'one','two')).target.should == ['two','one']
  end

  it "handles hash methods" do
    @adapter.call_proc(req_from_chain(@s_o, 'hash_arg', {:k => 'v'})).target.should == [:k]
  end

  it "handles one and hash methods" do
    @adapter.call_proc(req_from_chain(@s_o, 'one_hash_arg', 'arg', {:k => 'v'})).target.should == 'argk: v'
  end

  it "handles rest args" do
    pending "What to do about these"
    @adapter.call_proc(req_from_chain(@s_o, 'rest_arg', 'a','b','c','d')).target.should == 'a<->b<->c<->d'
  end

  it "errors on private methods" do
    expect {
      @adapter.call_proc(req_from_chain(@s_o, 'imprivate'))
    }.to raise_error NoMethodError
  end
  it "errors on unknown methods" do
    expect {
      @adapter.call_proc(req_from_chain(@s_o, 'notamethod'))
    }.to raise_error NoMethodError
  end

end

