$root_folder = File.dirname(__FILE__)

require_relative 'ruby/environment'
require_relative 'ruby/services/database'
require_relative 'ruby/services/aws'
require_relative 'ruby/shrine'
require_relative 'ruby/patches'

Dir["extensions/*.rb"].each    { |file| require_relative file }
Dir["models/**/*.rb"].each     { |file| require_relative file }
Dir["ruby/services/*.rb"].each { |file| require_relative file }
Dir["ruby/*.rb"].each          { |file| require_relative file }

require_relative 'auth/auth.rb'
require_relative 'admin/admin.rb'
require_relative 'site/CFC.rb'
require_relative 'checkout/checkout.rb'
require_relative 'reports/reports'

use Rack::Deflater

map "/" do
  run CFC
end

map "/admin" do
  run CFCAdmin
end

map "/auth" do
  run CFCAuth
end

map "/checkout" do
  run Checkout
end

map "/stripe" do
  run StripeRoutes
end

map "/models/slides" do
  run SlideRoutes
end

map "/models/classdefs" do
  run ClassDefRoutes
end

map "/models/events" do
  run EventRoutes
end

map "/models/staff" do
  run StaffRoutes
end

map "/models/customers" do
  run CustomerRoutes
end

map "/models/passes" do
  run PassRoutes
end

map "/models/settings" do
  run SettingRoutes
end

map "/reports" do
  run Reports
end

map "/door" do
  run Door
end 

map "/twilio" do
  run TwilioRoutes
end