require 'bundler'; Bundler.require(:default)
Dir["ruby/*.rb"].each { |file| require_relative file }

set :bind, '0.0.0.0'; set :server, 'thin'
set :views, File.dirname(__FILE__) + "/slim"
