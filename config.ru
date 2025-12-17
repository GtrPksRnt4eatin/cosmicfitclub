$root_folder = File.dirname(__FILE__)
require 'rack/ssl-enforcer'

require 'active_support'
require 'active_support/core_ext/date/calculations'
require 'active_support/core_ext/integer/inflections'

require_relative 'ruby/environment'
require_relative 'integrations/database'
require_relative 'integrations/aws'
require_relative 'ruby/shrine'
require_relative 'ruby/patches'

Dir["extensions/*.rb"].each    { |file| require_relative file }

require_relative 'auth/auth_helpers'
require_relative 'auth/auth'

Dir["integrations/*.rb"].each              { |file| require_relative file }
Dir["ruby/*.rb"].each                      { |file| require_relative file }
Dir["models/mixins/*.rb"].each             { |file| require_relative file }
Dir["models/**/*.rb"].each                 { |file| require_relative file }
Dir["printable/*.rb"].each                 { |file| require_relative file }
Dir["printable/*.rb"].each                 { |file| require_relative file }
Dir["printable/lib/*.rb"].each             { |file| require_relative file }
Dir["printable/background_jobs/*.rb"].each { |file| require_relative file }

require_relative 'admin/admin'
require_relative 'site/CFC'
require_relative 'checkout/checkout'
require_relative 'reports/reports'
require_relative 'user/user'
require_relative 'frontdesk/frontdesk'
require_relative 'offers/offers'

use Rack::SslEnforcer 
use Rack::Deflater

use Rack::Session::Cookie, :key => '_rack_session',
                           :path => '/',
                           #:expire_after => 60*60,
                           :same_site => :none,
                           :httponly => true,
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

map "/frontdesk" do
  run CFCFrontDesk
end

map "/checkout" do
  run Checkout
end

map "/stripe" do
  run StripeRoutes
end

map "/braintree" do
  run BraintreeRoutes
end

map "/models/giftcerts" do
  run GiftCertRoutes
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

map "/dmx" do
  run Dmx
end

map "/twilio" do
  run TwilioRoutes
end

map "/sms" do
  run TwilioRoutes
end

map "/models/schedule" do
  run ScheduleRoutes
end

map "/models/groups" do
  run GroupReservationRoutes
end

map "/models/locations" do
  run LocationRoutes
end

map '/models/nfc' do
  run NfcTagRoutes
end

map '/models/short_urls' do
  run ShortUrlRoutes
end

map "/offers" do
  run CFCOffers
end

map "/integrations/paypal" do
  run PayPalRoutes
end

map "/integrations/eventbrite" do
  run EventBriteRoutes
end

map "/integrations/facebook" do
  run FacebookRoutes
end

map '/integrations/twilio/video' do
  run TwilioVideo
end

map '/integrations/slackbot' do
  run SlackBot
end

# Send notification when app loads/restarts on Heroku
if ENV['DYNO']
  dyno_name = ENV['DYNO'] || 'unknown'
  Slack.custom("🚀 App started on Heroku - Dyno: #{dyno_name}", 'website_errors')
end

Calendar::subscribe_to_changes