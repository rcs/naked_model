require_relative '../orm_namespace'
class NakedModel::Adapter::ActiveRecord::Collection < NakedModel::Adapter
  include NakedModel::Adapter::OrmNamespace
  include NakedModel::Adapter::ActiveRecord
  WHITELIST = [:all, :count, :first, :last]

  def initialize
    @orm_classes = [::ActiveRecord::Base]
  end

  def create(request)
    request.target.create(request.body)
  end

  def handles?(*chain)
    t = chain.first

    if t.is_a? Class
      klass = t
    elsif t.is_a? ::ActiveRecord::Relation
      klass = t.klass
    else
      begin
        klass = t.proxy_association.reflection.klass
      rescue NoMethodError
        return nil
      end
    end

    klass < ::ActiveRecord::Base
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

  def interesting_methods(klass)
    methods = (klass.public_methods - platonic_class(klass).public_methods).reject { |m| m.to_s.match /^(_|original_)/ }
    ::Hash[methods.map { |m| [m,klass.method(m)] }]
  end

end
