class NakedModel::Adapter
  module ActiveModel::Collection
    WHITELIST = [:all, :count, :first, :last]

    def interesting_methods(klass)
      klass = collection_class(klass)
      methods = (klass.public_methods - platonic_class(klass).public_methods).reject { |m| m.to_s.match /^(_|original_)/ } + WHITELIST
      ::Hash[methods.map { |m| [m, klass.method(m)] }]
    end
  end
end
