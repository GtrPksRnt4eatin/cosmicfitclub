class EventBriteRoutes < Sinatra::Base

  post '/webhooks' do 
  	data = JSON.parse request.body.read
  	Slack.webhook("EventBrite Webhook: ", JSON.pretty_generate(data))
  end

end