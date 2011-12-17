require 'warden'
puts "#{__FILE__}"
require 'factory/ar_warden'
require 'naked_model'
require 'naked_model/adapter/active_record'
require 'naked_model/adapter/warden'

Warden::Manager.serialize_into_session{|user| user.id }
Warden::Manager.serialize_from_session{|id| User.find(id) }

Warden::Strategies.add(:trusting) do
  def valid?
    params['username']
  end
  def authenticate!
    puts "Finding with #{params['username']}"
    u = User.find_by_name(params['username'])
    puts "Found: #{u}"
    u.nil? ? fail!("User not found") : success!(u)
  end
end

use Rack::Session::Cookie, :secret => "replace this with some secret key"

use Warden::Manager do |manager|
  manager.default_strategies :trusting
  manager.failure_app = [401,"WTF"]
end

class AlwaysAuth
  def initialize(app)
    @app = app
  end
  def call(env)
    env['warden'].authenticate!(env)
    @app.call(env)
  end
end

Factory(:prolific_user)
Factory(:prolific_user)
Factory(:prolific_user)
Factory(:prolific_user)

use AlwaysAuth

run NakedModel.new( :adapters => [NakedModel::Adapter::Warden.new, NakedModel::Adapter::ActiveRecord::Collection.new, NakedModel::Adapter::ActiveRecord::Object.new] )



