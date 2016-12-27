require_relative 'ruby/environment'
require_relative 'ruby/services/database'
require_relative 'ruby/services/aws'
require_relative 'ruby/shrine'

Dir["extensions/*.rb"].each    { |file| require_relative file }
Dir["models/*.rb"].each        { |file| require_relative file }
Dir["ruby/services/*.rb"].each { |file| require_relative file }
Dir["ruby/*.rb"].each          { |file| require_relative file }

require_relative 'site/CFC.rb'
require_relative 'admin/admin.rb'

map "/" do
  run CFC
end

map "/admin" do
  run CFCAdmin
end