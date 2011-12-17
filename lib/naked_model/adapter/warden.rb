class NakedModel
  class Adapter::Warden < Adapter
  def find_base(name,env)
    if name == '~' and env['warden']
      puts "FOUND IT"
      env['warden'].user
    end
  end
  def handles?(name)
    name == "~"
  end

  def all_names
    []
  end

end
end
