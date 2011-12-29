require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'naked_model'
require 'naked_model/adapter/object'

describe NakedModel::Adapter::Object do
  before :each do
    @adapter = NakedModel::Adapter::Array.new
  end

  it "handles arrays" do
    @adapter.handles?([]).should be_true
  end

  it "allows first" do
    @adapter.call_proc(req_from_chain(['one','two'],'first')).target.should == 'one'
  end

  it "allows last" do
    @adapter.call_proc(req_from_chain(['one','two'],'last')).target.should == 'two'
  end

  it "allows index" do
    @adapter.call_proc(req_from_chain(['one','two','three'],2)).target.should == 'three'
  end


  it "doesn't allow other methods" do
    expect {
      @adapter.call_proc(req_from_chain([],'class'))
    }.to raise_error NoMethodError
  end

  it "returns not found for out of bounds" do
    expect {
      @adapter.call_proc(req_from_chain(['one'],99999))
    }.to raise_error NakedModel::RecordNotFound
  end
end

