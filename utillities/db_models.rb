require 'irb'
require_relative '../ruby/environment'
require_relative '../integrations/database'
require_relative '../integrations/aws'
require_relative '../ruby/shrine'

Dir["../models/mixins/*.rb"].each { |file| require_relative file unless /.*Routes.*/=~file }
Dir["../models/**/*.rb"].each     { |file| require_relative file unless /.*Routes.*/=~file }
Dir["../printables/*.rb"].each    { |file| require_relative file }

def reload_models
  Dir["printables/*.rb"].each    { |file| load file }
end

Dir.chdir("..")

binding.irb