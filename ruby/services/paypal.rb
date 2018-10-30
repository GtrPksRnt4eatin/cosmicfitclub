
class PaypalRoutes < Sinatra::Base

  post '/' do 
  	Slack.post(request.body.read)
  end

end