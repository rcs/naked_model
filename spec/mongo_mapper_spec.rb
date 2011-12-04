require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'naked_model'
require 'multi_json'

require_relative 'factory/mm'

require 'naked_model/adapter/mongo_mapper'

def comp_plucky(a,b)
  a.criteria.should == b.criteria
  a.collection.name.should == b.collection.name
  a.options.should == b.options
end

describe 'NakedModel::Adapter::MongoMapper::Collection' do

  before(:all) do
    @author = Factory(:prolific_author)
    @adapter = NakedModel::Adapter::MongoMapper::Collection.new
  end

  it 'Finds a base' do
    @adapter.find_base('Author').should == Author
  end

  it 'Doesnt respond to unknown names' do
    @adapter.find_base('Notaclass').should be_nil
  end

  it "handles mm collections" do
    @adapter.handles?(Author).should be_true
  end
  it "handles mm relatiokns" do
    @adapter.handles?(Author.first.books).should be_true
  end
  it "handles scopes" do
    @adapter.handles?(Book.published).should be_true
  end

  it "doesn't handle instance objects" do
    @adapter.handles?(Author.first).should be_false
  end

  it "doesn't handle instance objects through relationships" do
    @adapter.handles?(Book.first.author).should be_false
  end

  it 'Converts hexes to find models' do
    @adapter.call_proc(Author,@author.id.to_s)[:res].should == @author
  end
  it 'Returns not found on a not-found model' do
    expect {
      @adapter.call_proc(Author,'99999999')
    }.to raise_error NakedModel::RecordNotFound
  end


  it "allows defined methods (like scope) on collections" do
    comp_plucky(
      @adapter.call_proc(Book, 'published')[:res],
      Book.published
    )
  end

  it "ignores base MM methods" do
    expect {
      @adapter.call_proc(Book, 'keys')
    }.to raise_error NoMethodError
  end

  it "preserves scopes for chaining" do
    comp_plucky(
      @adapter.call_proc(@adapter.call_proc(Book,'published')[:res],'includes_6')[:res],
      Book.published.includes_6
    )
  end

  it "allows defined methods (like scope) on scopes" do
    comp_plucky(
      @adapter.call_proc(@author.books,'published')[:res],
      @author.books.published
    )
  end

end

describe 'NakedModel::Adapter::MongoMapper::Object' do

  before(:all) do
    @author = Factory(:prolific_author)
    @adapter = NakedModel::Adapter::MongoMapper::Object.new
  end

  it "handles instance objects" do
    @adapter.handles?(Book.first).should be_true
  end
  it "handles instance objects through relationships" do
    @adapter.handles?(Book.first.author).should be_true
  end

  it 'allows attributes' do
    @adapter.call_proc(@author,'name')[:res].should == @author.name
  end

  it 'allows associations' do
    @adapter.call_proc(@author,'books')[:res].should == @author.books
  end

  it 'allows locally defined methods' do
    @adapter.call_proc(@author,'do_books_rock')[:res].should == @author.do_books_rock
  end



  it "ignores generated non-read attribute methods" do
    @author.method(:name_before_type_cast).should_not be_nil
    expect {
      @adapter.call_proc(@author,'name_before_type_cast')
    }.to raise_error NoMethodError
  end

  it "ignores non-attribute, non-relation, non-local defined methods" do
    @author.method(:destroy).should_not be_nil
    expect {
      @adapter.call_proc(@author,'destroy')
    }.to raise_error NoMethodError
  end

end
