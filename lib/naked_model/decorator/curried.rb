class NakedModel::Decorator::Proc
  attr_accessor :curried
  def initialize(curried)
    self.curried = curried
  end

  def as_json(request)
    {
      :pending_arguments => "You're going to need some more arguments, partner"
    }
  end

  def rel(relation)
    curried.curry[relation]
  end
end
