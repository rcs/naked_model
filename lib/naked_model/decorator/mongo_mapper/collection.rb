class NakedModel::Decorator::MongoMapper::Collection
  attr_accessor :collection
  def initialize(collection)
    self.collection = collection
  end

  def as_json(request)
    {
#      collection.model_name.tableize => collection.all.map do |a|
      'stuff' => collection.all.map do |a|
        request.decorate(a).as_json(request.add_path(a.id))
      end,
      :links => [
        defined_on_collection.map do |relation|
          {:rel => relation, :href => request.add_path(relation).full_path }
        end,
        {:rel => 'self', :href => request.full_path}
      ]
    }
  end

  def rel(relation)
    if defined_on_collection.include? relation
      collection.method(relation.to_sym).to_proc.curry[]
    else
      res = collection.find(relation)
      raise NakedModel::RecordNotFound if res.nil?
      res
    end
  end

  # Create an object on the collection, raising `CreateError` with the message if it fails
  def create(request)
    begin
      created = collection.create!(request.body)
      request.next created, :path => [created.id.to_s]
    rescue ::MongoMapper::DocumentNotValid => e
      raise NakedModel::CreateError.new e.message
    end
  end


  private
  def defined_on_collection
    (collection.public_methods -
     platonic_collection.public_methods).
     reject { |m| m.to_s.match /^(_|original_)/ }
  end

  def platonic_collection
    platonic = Class.new
    platonic.send :include, ::MongoMapper::Document
    platonic
  end
end
