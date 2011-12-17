require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
eval "Rack::Builder.new {( " + File.read(File.dirname(__FILE__) + '/apps/warden.ru') + "\n )}"
