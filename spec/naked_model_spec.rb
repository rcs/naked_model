require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'rack/test'
require 'naked_model'
require 'naked_model/adapter/active_record'
require 'naked_model/adapter/array'
require 'naked_model/adapter/hash'
require 'multi_json'

require File.expand_path(File.dirname(__FILE__) + '/factory/ar')

stub_adapters = {
  :not_found => { :error => NakedModel::RecordNotFound },
  :no_method => { :error => NoMethodError },
  :create => { :error => NakedModel::CreateError },
  :update => { :error => NakedModel::UpdateError },
}

stub_adapters.keys.each do |k|
  stub_adapters[k][:class] = Class.new do
    def call_proc(request)
      raise stub_adapters[k][:error]
    end
  end
end






describe NakedModel do
  include Rack::Test::Methods
  it "instantiates" do
    app = NakedModel.new(:adapters => [NakedModel::Adapter::Hash.new({})])
    app.should_not be_nil
  end

  it "allows symbol names for adapters" do
    pending "Builder initialization"
    app = NakedModel.new do |builder|
      builder.adapter :hash
    end
    app.should_not be_nil
  end

  def app
    NakedModel.new :adapters => [
        NakedModel::Adapter::Array.new,
        NakedModel::Adapter::Hash.new( 'hash' => { 'one' => 1, 'two' => 2, 'deep' => { 'deeper' => 3 } } ),
      ]
  end

  before(:all) do
    @hash = { 'hash' => { 'one' => 1, 'two' => 2, 'deep' => { 'deeper' => 3 } } }
  end

  it "responds to a listing request" do
    get '/'
    MultiJson.decode(last_response.body).should == {
      "links"=>[
        {"rel"=>"hash", "href"=>"http://example.org/hash"}
      ]
    }
  end

  it "404s on a non-known name" do
    get '/notaname'
    last_response.status.should == 404
  end

  it "returns an index on a listing page" do
    get '/hash'
    MultiJson.decode(last_response.body).should == @hash['hash'].merge( 'links' => [{ 'rel' => 'self', 'href' => 'http://example.org/hash' }] )
  end

  it 'finds models defined' do
    get '/hash/one'
    MultiJson.decode(last_response.body).should == { "val" => @hash['hash']['one'] }
  end
  it 'returns 404 on a not-found model' do
    get '/hash/999999999999999'
    last_response.status.should ==  404
  end
  it 'returns 404 on a not-found method' do
    get '/hash/notamethod'
    last_response.status.should ==  404
  end
  it 'follows deep' do
    get '/hash/deep/deeper'
    MultiJson.decode(last_response.body).should == { "val" => @hash['hash']['deep']['deeper'] }
  end

  it "responds to basic hash calls" do
    get '/hash/deep'
    MultiJson.decode(last_response.body).should == { "deeper" => 3 }.merge( 'links' => [{ 'rel' => 'self', 'href' => 'http://example.org/hash/deep' }] )
  end
  it "responds to deep hash calls" do
    get '/hash/deep/deeper'
    MultiJson.decode(last_response.body).should == { "val" => 3 }
  end

  it "creates a new object with post" do
    post '/hash', '{ "name": "llama", "llama": 1 }'
    last_response.status.should == 201
    get '/hash/llama'
    MultiJson.decode(last_response.body).should == { "val" => 1 }
  end
  it "errors on a dupiicate" do
    post '/hash', '{ "name": "llama", "llama": 1 }'
    post '/hash', '{ "name": "llama", "llama": 1 }'
    last_response.status.should == 409
  end

  it "updates a new object with put" do
    put '/hash', '{ "color": "red" }'
    last_response.status.should == 200
    get '/hash/color'
    MultiJson.decode(last_response.body).should == { "val" => 'red' }
  end
end

describe "error handling" do
  class NoMethodAdapter < NakedModel::Adapter
    def handles?(*chain); true; end
    def call_proc(request)
      raise NoMethodError
    end
  end

  class NotFoundAdapter < NakedModel::Adapter
    def handles?(*chain); true; end
    def call_proc(request)
      raise NakedModel::RecordNotFound.new "Record Not Found"
    end
  end

  class CreateFailAdapter < NakedModel::Adapter
    def handles?(*chain); true; end
    def call_proc(request)
      raise NakedModel::CreateError.new "Create Failed"
    end
  end

  class UpdateFailAdapter < NakedModel::Adapter
    def handles?(*chain); true; end
    def call_proc(request)
      raise NakedModel::UpdateError.new "Update failed"
    end
  end

  it "handles not having an adapter to serve a thing" do
    browser = Rack::Test::Session.new(NakedModel.new( :adapters => [NakedModel::Adapter::Hash.new({'llama' => []})]))
    browser.get '/llama/1'
    browser.last_response.status.should == 404
  end

  it "handles NoMethod from adapters" do
    browser = Rack::Test::Session.new(NakedModel.new( :adapters => [NoMethodAdapter.new,NakedModel::Adapter::Hash.new({'llama' => 1})]))
    browser.get '/llama/humps'
    browser.last_response.status.should == 404
  end
  it "handles NotFound from adapters" do
    browser = Rack::Test::Session.new(NakedModel.new( :adapters => [NotFoundAdapter.new,NakedModel::Adapter::Hash.new({'llama' => 1})]))
    browser.get '/llama/humps'
    browser.last_response.status.should == 404
  end
  it "handles CreateError from adapters" do
    browser = Rack::Test::Session.new(NakedModel.new( :adapters => [CreateFailAdapter.new,NakedModel::Adapter::Hash.new({'llama' => 1})]))
    browser.get '/llama/humps'
    browser.last_response.status.should == 409
  end
  it "handles UpdateError from adapters" do
    browser = Rack::Test::Session.new(NakedModel.new( :adapters => [UpdateFailAdapter.new,NakedModel::Adapter::Hash.new({'llama' => 1})]))
    browser.get '/llama/humps'
    browser.last_response.status.should == 406
  end
end

describe 'link replacement' do
  before :all do
    @nm = NakedModel.new :adapters => [NakedModel::Adapter.new]
    @request = NakedModel::Request.from_env(basic_rack_env)
    @request.path = ['context']
  end
  it "Joins on nothing arrays" do
    @nm.rel_to_url(['a','b','c'],'root/context').should == 'a/b/c'
  end

  it "joins against context for '.'" do
    @nm.rel_to_url(['.','a','b'],'root/context').should == 'root/context/a/b'
  end

  it "Finds :link keys in objects and replaces urls" do
    @nm.replace_links({
      :name => 'llama',
      :links => [
        {:rel => 'things', :href => ['.','b','c']}
      ]
    },@request).should == {
      :name => 'llama',
      :links => [
        {:rel => 'things', :href => 'http://example.org/context/b/c'}
      ]
    }
  end

  it "sets context to self if it exists for replacement" do
    @nm.replace_links({
      :name => 'llama',
      :links => [
        {:rel => 'things', :href => ['.','c','d']},
        {:rel => 'self', :href => ['.','a','b']},
      ]}, @request).should == {
        :name => 'llama',
        :links => [
          {:rel => 'things', :href => 'http://example.org/context/a/b/c/d'},
          {:rel => 'self', :href => 'http://example.org/context/a/b'},
        ]
      }
  end
end
