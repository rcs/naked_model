# Adapter class to turn a request of '/~' into an authenticated user object
class NakedModel
  class Adapter::Warden < Adapter

    # If the  request starts with '~', turn it into the warden user
    def find_base(request)
      # In a Warden routed environment env['warden'] is set
      return nil unless request.target == '~' and request.request.env['warden']

      return request.replace request.request.env['warden'].user
    end
  end
end
