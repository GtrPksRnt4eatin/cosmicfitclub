
class PaypalRoutes < Sinatra::Base

  post '/webhooks' do 
  	Slack.post(request.body.read)
  end

end