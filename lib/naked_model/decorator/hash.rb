# Basic adapter for `Hash` objects
class NakedModel::Decorator::Hash
  attr_accessor :hash
  def initialize(h)
    self.hash = h
  end

  def as_json
    hash.select { |k,v|
      basic_types.any? { |t| v.kind_of? t }
    }.merge :links => [
      hash.select { |k,v|
        basic.types.none? { |t| v.kind_of? t }
      }.map { |k,v|
        { :rel => k, href => k }
      }
    ]
  end

  def update(request)
    hash.merge! request.body
  end

  def rel(relation)
    hash.fetch relation
  end

  def decorate(obj)
    raise NakedModel::NoMethodError
  end

  private
  def basic_types
    [String, Numeric,Symbol,Class]
  end
end
