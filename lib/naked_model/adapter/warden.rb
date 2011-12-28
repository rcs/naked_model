class NakedModel
  class Adapter::Warden < Adapter
  def find_base(request)
    if request.chain.first == '~' and request.env['warden']
      return request.replace env['warden'].user
    else
      return nil
    end
  end

  def all_names
    []
  end

end
end
