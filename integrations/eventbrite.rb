require 'eventbrite_sdk'

class EventBriteRoutes < Sinatra::Base

  EventbriteSDK.token = ENV["EVENTBRITE_KEY"]

  post '/webhooks' do 

  	event = JSON.parse request.body.read
  	event["api_object"] = get_event_obj(event)

  	case event['config']['action']
     
    when 'order.placed'
      Slack.custom("EventBrite Order Placed:\r\revent_id: #{event["api_object"]["event_id"]}\rname: #{event["api_object"]["name"]}\remail: #{event["api_object"]["email"]}")
      ( Slack.custom("But Customer Already Exists!"); return ) if Customer::exists? event["api_object"]["email"]
      custy = Customer.get_from_email( event["api_object"]["email"], event["api_object"]["name"] )
    else
      Slack.webhook('EventBrite Webhook: ', JSON.pretty_generate(event) )
    end

  end

  def get_event_obj(event)
    Slack.post(event['api_url'])
    /https:\/\/www.eventbriteapi.com\/v3\/(<?path>.*)/ =~ event['api_url']
    EventbriteSDK::get({ :url => path })
  end

end