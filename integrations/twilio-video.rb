class TwilioVideo < Sinatra::Base

  post '/' 
    Slack.webhook("Video Webhook", params[:StatusCallbackEvent]);
  	case params[:StatusCallbackEvent]
  	when 'room-created'
  	when 'room-ended'
  	when 'participant-connected'
  	when 'participant-disconnected'
  	end
  	status 204
  	""
  end

end
  