ENV['DB_ENV'] = 'test'
require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
end if ENV['COVERAGE']

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'

def req_from_chain(*chain)
  NakedModel::Request.new :chain => chain
end

def basic_rack_env(h={})
  {
    'rack.url_scheme' => 'http',
    'HTTP_HOST' => 'example.org:80',
    'SCRIPT_NAME' => '',
    'rack.input' => StringIO.new(''),
    'rack.errors' => $stderr,
    'CONTENT_LENGTH' => 0
  }.merge(h)
end

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}
