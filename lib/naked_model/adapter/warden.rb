# Adapter class to turn a request of '~' into an authenticated user object
class NakedModel
  class Adapter::Warden < Adapter

    # If the  request starts with '~', turn it into the warden user
    def find_base(request)
      return nil unless request.target == '~' and request.env['warden']

      return request.replace env['warden'].user
    end
  end
end
