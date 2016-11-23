require 'web.rb'
require 'admin.rb'

map "/" 
  run CFC::Site
end

map "/admin"
  run CFC::admin
end