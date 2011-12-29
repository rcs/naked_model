# Helper module for ActiveModel conforming collections
class NakedModel
  class Adapter
    module ActiveModel
      module Collection
        # Useful methods to be able to call on collections
        WHITELIST = [:all, :count, :first, :last]


        # Return methods defined on the collection, discarding previous ancestry methods
        def interesting_methods(klass)
          # Divine the underlying class for a class -- useful for things like
          # association proxies that define themselves as arrays
          klass = collection_class(klass)

          # The methods we care about are
          ::Hash[
            # public methods on the class
            (klass.public_methods -
              # without helper methods from their base
              platonic_class(klass).public_methods +
              # (but including the whitelist)
              WHITELIST
            ).
            # rejecting methods that were aliased away
            reject { |m| m.to_s.match /^(_|original_)/ }.
            map { |m|
            # And we'll return their method definitions 
              [m, klass.method(m)] 
            }
          ]
        end
      end
    end
  end
end
