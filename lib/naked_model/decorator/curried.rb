class NakedModel::Decorator::Proc
  attr_accessor :curried
  def initialize(curried)
    self.curried = curried
  end

  def as_json
    raise NotImplementedError
  end

  def rel(relation)
    curried.curry[relation]
  end
end
