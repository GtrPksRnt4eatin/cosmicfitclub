require 'irb'
require_relative '../ruby/environment'
require_relative '../integrations/database'
require_relative '../integrations/aws'
require_relative '../ruby/shrine'

Dir["../models/mixins/*.rb"].each  { |file| require_relative file unless /.*Routes.*/=~file }
Dir["../models/**/*.rb"].each      { |file| require_relative file unless /.*Routes.*/=~file }
Dir["../printable/lib/*.rb"].each { |file| require_relative file }
Dir["../printable/*.rb"].each     { |file| require_relative file }

def reload
  Dir["printable/lib/*.rb"].each { |file| load file }
  Dir["printable/*.rb"].each        { |file| load file }
end

Dir.chdir("..")

binding.irb