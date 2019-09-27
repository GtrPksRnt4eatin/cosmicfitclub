require_relative './environment'
require_relative '../integrations/database'
require_relative 'ruby/shrine'

Dir["models/mixins/*.rb"].each { |file| require_relative file }
Dir["models/**/*.rb"].each     { |file| require_relative file }
