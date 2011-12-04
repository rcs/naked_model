require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'naked_record'
require 'multi_json'

require_relative 'factory/ar'

require 'naked_record/adapter/active_record'


describe 'NakedRecord::Adapter::ActiveRecord::Collection' do

  before(:all) do
    artist = Factory(:prolific_artist)
    @adapter = NakedRecord::Adapter::ActiveRecord::Collection.new
  end

  it 'Finds a base' do
    @adapter.find_base('Artist').should == Artist
  end

  it 'Doesnt respond to unknown names' do
    @adapter.find_base('Notaclass').should be_nil
  end

  it "handles AR collections" do
    @adapter.handles?(Artist).should == true
  end
  it "handles AR proxies" do
    @adapter.handles?(Artist.find(1).cds).should == true
  end
  it "handles scopes" do
    @adapter.handles?(Track.including_one_in_title).should == true
  end

  it "doesn't handle instance objects" do
    @adapter.handles?(Artist.find(1)).should be_nil
  end

  it 'Delegates to all for classes' do
    @adapter.display(Artist).should == Artist.all
  end

  it 'Converts numbers to find models' do
    @adapter.call_proc(Artist,'1')[:res].should == Artist.find(1)
  end

  it 'Returns not found on a not-found model' do
    expect {
      @adapter.call_proc(Artist,'99999999')
    }.to raise_error NakedRecord::RecordNotFound
  end

  it "allows defined methods (like scope) on collections" do
    @adapter.call_proc(Track,'including_one_in_title')[:res].should == Track.including_one_in_title
  end

  it "ignores AR base methods" do
    Artist.method(:columns).should_not be_nil
    expect {
      @adapter.call_proc(Artist, 'columns')
    }.to raise_error NoMethodError
  end
end

describe 'NakedRecord::Adapter::ActiveRecord::Object' do
  before(:all) do
    @artist = Factory(:prolific_artist)
    @adapter = NakedRecord::Adapter::ActiveRecord::Object.new
  end

  it 'allows attributes' do
    @adapter.call_proc(@artist,'name')[:res].should == @artist.name
  end

  it 'allows associations' do
    @adapter.call_proc(@artist,'cds')[:res].should == @artist.cds
  end

  it "allows defined methods on objects" do
    @adapter.call_proc(@artist,'llamas')[:res].should == @artist.llamas
  end

  it "ignores generated non-read attribute methods" do
    @artist.method(:name_change).should_not be_nil
    expect {
      @adapter.call_proc(@artist,'name_change')
    }.to raise_error NoMethodError
  end

  it "ignores non-attribute, non-relation, non-local defined methods" do
    @artist.method(:destroy).should_not be_nil
    expect {
      @adapter.call_proc(@artist,'destroy')
    }.to raise_error NoMethodError
  end
end
