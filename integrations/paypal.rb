
class PayPalRoutes < Sinatra::Base

  post '/webhooks' do 
  	Slack.webhook("PayPal Webhook: ", request.body.read)
  end

end