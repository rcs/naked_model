require_relative '../orm_namespace'
require 'naked_model/adapter/active_model/collection'
class NakedModel::Adapter::ActiveRecord::Collection < NakedModel::Adapter
  include NakedModel::Adapter::OrmNamespace
  include NakedModel::Adapter::ActiveRecord
  include NakedModel::Adapter::ActiveModel::Collection

  def initialize
    @orm_classes = [::ActiveRecord::Base]
  end

  def create(request)
    request.target.create(request.body)
  end

  def handles?(*chain)
    collection_class(chain.first)
  end

  def collection_class(obj)
    if obj.is_a? Class
      klass = obj
    elsif obj.is_a? ::ActiveRecord::Relation
      klass = obj.klass
    else
      begin
        klass = obj.proxy_association.reflection.klass
      rescue NoMethodError
        return nil
      end
    end

    if klass < ::ActiveRecord::Base
      klass
    else
      nil
    end
  end

  def display(obj)
    obj.all
  end

  def call_proc(request)
    begin
      super
    rescue NoMethodError => e
      if is_num? request.method
        begin
          request.next request.target.find(request.method) 
        rescue ::ActiveRecord::RecordNotFound
          raise NakedModel::RecordNotFound.new(request.method)
        end
      else
        raise e
      end
    end
  end

end
