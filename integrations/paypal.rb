require 'paypal-sdk-rest'
include PayPal::SDK::REST

PayPal::SDK::REST.set_config(
  :mode => 'live',
  :client_id => ENV['PAYPAL_ID'],
  :client_secret => ENV['PAYPAL_SECRET'],
  :ssl_options => {}
)

class PayPalRoutes < Sinatra::Base

  post '/webhooks' do 
  	data = JSON.parse request.body.read
  	Slack.webhook("PayPal Webhook: #{data['event_type']}", JSON.pretty_generate(data))
  end

end