require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rack'

app = eval "Rack::Builder.new {( " + File.read(File.dirname(__FILE__) + '/../apps/warden.ru') + "\n )}"

class MockWarden
  def user
    "I'm a user"
  end
end
describe "NakedModel::Adapter::Warden" do
  before :all do
    @adapter = NakedModel::Adapter::Warden.new
  end
  it "replaces ~ with the current user" do
    @adapter.find_base(NakedModel::Request.from_env(basic_rack_env 'warden' => MockWarden.new, 'PATH_INFO' => '/~')).target.should == "I'm a user"
  end
end
