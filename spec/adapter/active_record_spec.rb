require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'naked_model'
require 'multi_json'


require 'naked_model/adapter/active_record'
require_relative '../factory/ar'


describe "NakedModel::Adapter::ActiveRecord" do
  describe 'NakedModel::Adapter::ActiveRecord::Collection' do

    before(:all) do
      artist = Factory(:prolific_artist)
      @adapter = NakedModel::Adapter::ActiveRecord::Collection.new
    end

    it 'Finds a base' do
      @adapter.find_base(NakedModel::Request.new(:chain => ['Artist'])).chain.first == Artist
    end

    it 'Displays the collection' do
      @adapter.display(Artist).should == [
        {
          "id" => 1,
          "name" => "Artist1",
          :links => [
            {:rel=>"self", :href=>[".", "1"]},
            {:rel=>"cds",  :href=>[".", "cds"]}
          ]
        }
      ]
    end

    it 'Doesnt respond to unknown names' do
      @adapter.find_base(NakedModel::Request.new(:chain => ['Notaclass'])).should be_nil
    end

    it "handles AR collections" do
      @adapter.handles?(Artist).should be_true
    end
    it "handles AR proxies" do
      @adapter.handles?(Artist.find(1).cds).should be_true
    end
    it "handles scopes" do
      @adapter.handles?(Track.including_one_in_title).should be_true
    end

    it "doesn't handle instance objects" do
      @adapter.handles?(Artist.find(1)).should be_nil
    end

    it 'Converts numbers to find models' do
      # TODO
      @adapter.call_proc(NakedModel::Request.new(:chain => [Artist,'1'])).chain.first.should == Artist.find(1)
    end

    it 'Returns not found on a not-found model' do
      expect {
        @adapter.call_proc(NakedModel::Request.new :chain => [Artist,'99999999'] )
      }.to raise_error NakedModel::RecordNotFound
    end

    it "allows defined methods (like scope) on collections" do
      @adapter.call_proc(NakedModel::Request.new(:chain => [Track,'including_one_in_title'])).chain.first.should == Track.including_one_in_title
    end

    it "ignores AR base methods" do
      Artist.method(:columns).should_not be_nil
      expect {
        @adapter.call_proc(NakedModel::Request.new :chain => [Artist, 'columns'])
      }.to raise_error NoMethodError
    end

    it "creates new entities" do
      artist = @adapter.call_proc(NakedModel::Request.new :chain => [Artist,'create'], :body => {:name => 'Sloppy Joe'}).target
      artist.should_not be_nil
      artist.persisted?.should == true
    end

    it "errors on creation fail" do
      @adapter.call_proc(NakedModel::Request.new :chain => [Artist,'create'], :body => {:name => 'Hamburger Helper'})
      expect {
        @adapter.call_proc(NakedModel::Request.new :chain => [Artist,'create'], :body => {:name => 'Hamburger Helper'})
      }.to raise_error NakedModel::CreateError
    end
  end

  describe 'NakedModel::Adapter::ActiveRecord::Object' do
    before(:all) do
      @artist = Factory(:prolific_artist)
      @adapter = NakedModel::Adapter::ActiveRecord::Object.new
    end

    it 'handles AR objects' do
      @adapter.handles?(Artist.find(1)).should be_true
    end

    it 'allows attributes' do
      @adapter.call_proc(NakedModel::Request.new(:chain => [@artist,'name'])).chain.first.should == @artist.name
    end

    it 'allows associations' do
      @adapter.call_proc(NakedModel::Request.new(:chain => [@artist,'cds'])).chain.first.should == @artist.cds
    end

    it "allows defined methods on objects" do
      @adapter.call_proc(NakedModel::Request.new(:chain => [@artist,'llamas'])).chain.first.should == @artist.llamas
    end

    it "ignores generated non-read attribute methods" do
      @artist.method(:name_change).should_not be_nil
      expect {
        @adapter.call_proc( NakedModel::Request.new :chain => [@artist,'name_change'] )
      }.to raise_error NoMethodError
    end

    it "ignores non-attribute, non-relation, non-local defined methods" do
      @artist.method(:destroy).should_not be_nil
      expect {
        @adapter.call_proc(NakedModel::Request.new :chain => [@artist,'destroy'] )
      }.to raise_error NoMethodError
    end

    it "updates objects" do
      @adapter.call_proc(NakedModel::Request.new( :chain => [@artist,'update'], :body => { :name => 'John Doe' } ) ).target.name.should == 'John Doe'
    end

    it "aborts on validation failures (length on name)" do
      expect {
        @adapter.call_proc(NakedModel::Request.new( :chain => [@artist,'update'], :body => { :name => '' } ) )
      }.to raise_error NakedModel::UpdateError
    end

    it "displays an object" do
      @adapter.display(@artist).should == {
        "id" => @artist.id,
        "name" => @artist.name,
        :links => [
          {:rel => 'self', :href => ['.']},
          {:rel => 'cds', :href => ['.','cds']}
        ]
      }
    end
  end
end
