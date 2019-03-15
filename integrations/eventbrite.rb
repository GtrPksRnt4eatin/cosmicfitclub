require 'eventbrite_sdk'

class EventBriteRoutes < Sinatra::Base

  EventbriteSDK.token = ENV["EVENTBRITE_KEY"]

  post '/webhooks' do 
  	data = JSON.parse request.body.read
  	Slack.webhook("EventBrite Webhook: ", JSON.pretty_generate(data))
  end

end