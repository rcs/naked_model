require_relative '../orm_namespace'
class NakedModel::Adapter::ActiveRecord::Collection < NakedModel::Adapter
  include NakedModel::Adapter::OrmNamespace
  include NakedModel::Adapter::ActiveRecord
  WHITELIST = [:all, :count, :first, :last]

  def initialize
    @orm_classes = [::ActiveRecord::Base]
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

  def call_proc(*chain)
    target,method,*remaining = chain

    begin
      super
    rescue NoMethodError
      if is_num? method
        begin
          {:res => target.find(method), :remaining => remaining}
        rescue ::ActiveRecord::RecordNotFound
          raise NakedModel::RecordNotFound.new(method)
        end
      else
        raise NoMethodError.new(method)
      end
    end
  end

  def interesting_methods(klass)
    (klass.public_methods - platonic_class(klass).public_methods).reject { |m| m.to_s.match /^(_|original_)/ }
  end

end
