require 'active_record'

module NakedModel::Adapter::ActiveRecord
  require_relative 'active_record/object'
  require_relative 'active_record/collection'

  def platonic_class(klass)
    platonic = Class.new(::ActiveRecord::Base)
    # Build associations
    klass.reflect_on_all_associations.each do |assoc|
      builder = "::ActiveRecord::Associations::Builder::" +  assoc.macro.to_s.classify
      builder.constantize.send(:build, platonic, assoc.name,assoc.options)
    end
    # TODO aggregations

    # TODO columns

    platonic
  end
end
