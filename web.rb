require 'bundler'; Bundler.require(:default)

require_relative 'ruby/environment'
require_relative 'ruby/database'

Dir["models/*.rb"].each { |file| require_relative file }
Dir["ruby/*.rb"].each   { |file| require_relative file }

set :bind, '0.0.0.0'; set :server, 'thin'
set :views, File.dirname(__FILE__) + "/slim"