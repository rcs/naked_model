require 'active_record'

# Adapter for ActiveRecord
module NakedModel::Adapter::ActiveRecord
  # Load the collection and object adapters for AR
  require_relative 'active_record/object'
  require_relative 'active_record/collection'
  require_relative 'active_model/collection'

  ActiveRecord::Base.include_root_in_json = false
  # Create a new anonymous class that mimics the ancestry hierarchy of `klass`
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

  private
  def ar_classes
    classes = [ActiveRecord::Base]
    begin # Handle transition to ActiveRecord::Model mixin capabilities
      classes << Kernel.const_get('ActiveRecord::Model')
    rescue NameError
    end
    classes
  end
end
