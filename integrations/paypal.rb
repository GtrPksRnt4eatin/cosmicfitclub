class PayPalRoutes < Sinatra::Base

  post '/webhooks' do 
  	data = JSON.parse request.body.read
  	Slack.webhook("PayPal Webhook: #{data['event_type']}", JSON.pretty_generate(data))
  end

end