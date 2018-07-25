$root_folder = File.dirname(__FILE__)
require 'rack/ssl-enforcer'

require 'active_support'
require 'active_support/core_ext/date/calculations'

require_relative 'ruby/environment'
require_relative 'ruby/services/database'
require_relative 'ruby/services/aws'
require_relative 'ruby/shrine'
require_relative 'ruby/patches'

Dir["extensions/*.rb"].each    { |file| require_relative file }
Dir["models/mixins/*.rb"].each { |file| require_relative file }
Dir["models/**/*.rb"].each     { |file| require_relative file }
Dir["ruby/services/*.rb"].each { |file| require_relative file }
Dir["ruby/*.rb"].each          { |file| require_relative file }

require_relative 'auth/auth'
require_relative 'admin/admin'
require_relative 'site/CFC'
require_relative 'checkout/checkout'
require_relative 'reports/reports'
require_relative 'user/user'

use Rack::SslEnforcer
use Rack::Deflater

use Rack::Session::Cookie, :key => '_rack_session',
                           :path => '/',
                           :expire_after => 2592000,
                           :secret => 'asdf123897798128bkjwekhakhjsk38389721387932179831hjsdfkj'

map "/" do 
  run CFC
end

map "/admin" do
  run CFCAdmin
end

map "/auth" do
  run CFCAuth
end

map "/user" do
  run CFCuser
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

map "/models/rentals" do
  run RentalRoutes
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

map "/models/memberships" do
  run MembershipRoutes
end

map "/models/hourly" do
  run HourlyRoutes
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

map "/models/schedule" do
  run ScheduleRoutes
end