require 'addressable/uri'
require 'naked_model/adapter/orm_namespace'
require 'naked_model/adapter/active_model/collection'

class NakedModel::Adapter::MongoMapper::Collection < NakedModel::Adapter
  include NakedModel::Adapter::MongoMapper
  include NakedModel::Adapter::OrmNamespace
  include NakedModel::Adapter::ActiveModel::Collection

  def initialize
    @orm_classes = [::MongoMapper::Document]
  end

  def create(request)
    begin
      request.target.create(request.body)
    rescue ::MongoMapper::DocumentNotValid => e
      raise NakedModel::DuplicateError.new e.message
    end
  end

  def handles?(*chain)
    collection_class(chain.first)
  end

  def all_names
    ::MongoMapper::Document.descendants.select { |a| orm_class? a.to_s }.map { |a|
      [
        { :rel => a.to_s.underscore, :href => ['/' , a.to_s.underscore] },
      ]
    }
  end

  def collection_class(obj)
    return obj if obj.is_a? Class and obj < ::MongoMapper::Document

    if obj.is_a? ::Plucky::Query
      obj.model
    elsif obj.is_a? ::Array
      begin
        obj.proxy_association.klass
      rescue NoMethodError
        nil
      end
    else
      nil
    end

  end

  def display(obj)

    res = obj.all.map do |a|
      # TODO NakedModel::display(obj)
      a.as_json.merge(
      {
        :links => [
          { :rel => 'self', :href => ['/' , a.class.to_s.underscore, a.id.to_s] },
          *association_names(a).map { |n| {:rel => n, :href => ['/',a.class.to_s.underscore, a.id.to_s,n.to_s]}}
        ]})
    end

    res
  end

  def call_proc(request)
    begin
      super
    rescue NoMethodError
      if /^[[:xdigit:]]+$/ === request.method
        res = request.target.find(request.method)
        raise NakedModel::RecordNotFound if res.nil?
        request.next res
      else
        raise NoMethodError.new(request.method)
      end
    end
  end

end
