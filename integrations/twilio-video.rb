require 'twilio-ruby'

class TwilioVideo < Sinatra::Base

  post '/' do
  	case params[:StatusCallbackEvent]
  	when 'room-created'
  		Slack.custom("Video Room Created: #{params[:RoomName]}")
  	when 'room-ended'
  		client = Twilio::REST::Client.new ENV['TWILIO_SID'], ENV['TWILIO_AUTH_TOKEN']
  		list = client.video.rooms(params[:RoomSid]).participants.list()
  		list = list.map{ |x| "#{x.identity} - #{x.start_time} - #{x.duration}"}.join("\r\n")
  		Slack.webhook("Video Room Ended:", "```#{list}```")
  	when 'participant-connected'
  	when 'participant-disconnected'
  	end
  	status 204
  	""
  end

end
  