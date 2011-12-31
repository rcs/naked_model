require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'naked_model'
require 'multi_json'

require_relative '../factory/mm'

require 'naked_model/adapter/mongo_mapper'

def comp_plucky(a,b)
  a.criteria.should == b.criteria
  a.collection.name.should == b.collection.name
  a.options.should == b.options
end

describe 'NakedModel::Adapter::MongoMapper::Collection' do

  before(:all) do
    clear_database
    @author = Factory(:prolific_author)
    @adapter = NakedModel::Adapter::MongoMapper::Collection.new
  end

  it 'Finds a base' do
    @adapter.find_base(NakedModel::Request.new(:chain => ['Author'])).target.should == Author
  end

  it 'tells us the names registered' do
    @adapter.all_names.should == [
      {:rel=>"authors", :href=>[".", "author"]},
      {:rel=>"books", :href=>[".", "book"]},
      {:rel=>"desks", :href=>[".", "desk"]}
    ]
  end

  it "displays a collection" do
    @adapter.display(Author).should == [
      {
        "name" => Author.first.name,
        "id" => Author.first.id,
        :links => [
          {:rel => 'self', :href => ['.',Author.first.id.to_s]},
          {:rel => 'books', :href => ['.','books']},
          {:rel => 'desk', :href => ['.','desk']},
        ]
      }
    ]
  end

  it 'Doesnt respond to unknown names' do
    @adapter.find_base(NakedModel::Request.new(:chain => ['Notaclass'])).should be_nil
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
  it "doesn't handle non proxy arrays" do
    @adapter.handles?([]).should be_false
  end


  it "doesn't handle instance objects through relationships" do
    @adapter.handles?(Book.first.author).should be_false
  end

  it 'Converts hexes to find models' do
    @adapter.call_proc(NakedModel::Request.new(:chain => [Author,@author.id.to_s])).target.should == @author
  end
  it 'Returns not found on a not-found model' do
    expect {
      @adapter.call_proc(NakedModel::Request.new :chain => [Author,'99999999'])
    }.to raise_error NakedModel::RecordNotFound
  end


  it "allows defined methods (like scope) on collections" do
    comp_plucky(
      @adapter.call_proc(NakedModel::Request.new(:chain => [Book, 'published'])).target,
      Book.published
    )
  end

  it "ignores base MM methods" do
    expect {
      @adapter.call_proc(NakedModel::Request.new :chain => [Book, 'keys'])
    }.to raise_error NoMethodError
  end

  it "preserves scopes for chaining" do
    comp_plucky(
      @adapter.call_proc(
        NakedModel::Request.new :chain => [
          @adapter.call_proc(NakedModel::Request.new :chain => [Book,'published']).target,
          'includes_6']
      ).target,
      Book.published.includes_6
    )
  end

  it "allows defined methods (like scope) on scopes" do
    comp_plucky(
      @adapter.call_proc(NakedModel::Request.new(:chain => [@author.books,'published'])).target,
      @author.books.published
    )
  end

  it "creates new authors" do
    author = @adapter.create(NakedModel::Request.new :chain => [Author], :body => {:name => 'Sloppy Joe'}).target
    author.should_not be_nil
    author.persisted?.should == true
  end

  it "error on bad creates (duplicate name)" do
    @adapter.create(NakedModel::Request.new :chain => [Author], :body => {:name => 'Hamburger Helper'})
    expect {
      @adapter.create(NakedModel::Request.new :chain => [Author], :body => {:name => 'Hamburger Helper'})
    }.to raise_error NakedModel::CreateError
  end

end

describe 'NakedModel::Adapter::MongoMapper::Object' do

  before(:each) do
    clear_database
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
    @adapter.call_proc(NakedModel::Request.new(:chain => [@author,'name'])).target.should == @author.name
  end

  it 'allows associations' do
    @adapter.call_proc(NakedModel::Request.new(:chain => [@author,'books'])).target.should == @author.books
  end

  it 'allows locally defined methods' do
    @adapter.call_proc(NakedModel::Request.new(:chain => [@author,'do_books_rock'])).target.should == @author.do_books_rock
  end



  it "ignores generated non-read attribute methods" do
    @author.method(:name_before_type_cast).should_not be_nil
    expect {
      @adapter.call_proc(NakedModel::Request.new :chain => [@author,'name_before_type_cast'])
    }.to raise_error NoMethodError
  end

  it "ignores non-attribute, non-relation, non-local defined methods" do
    @author.method(:destroy).should_not be_nil
    expect {
      @adapter.call_proc(NakedModel::Request.new :chain => [@author,'destroy'])
    }.to raise_error NoMethodError
  end

  it "allows updates to author" do
    @adapter.call_proc(NakedModel::Request.new( :chain => [@author,'update'], :body => { :name => 'John Doe' } ) ).target.name.should == 'John Doe'
  end

  it "aborts on validation failures (length on name)" do
    expect {
      @adapter.call_proc(NakedModel::Request.new( :chain => [@author,'update'], :body => { :name => '' } ) )
    }.to raise_error NakedModel::UpdateError
  end

  it "displays objects correctly" do
    @adapter.display(@author).should == {
      'name' => @author.name,
      :links => [
        {:rel => 'self', :href => ['.']},
        {:rel => 'books', :href => ['.', 'books']},
        {:rel => 'desk', :href => ['.', 'desk']},
      ]
    }
  end


end
