class TwilioVideo < Sinatra::Base

  post '/' do
  	Slack.webhook("Video Webhook", request.body.read);
  	status 204
  	""
  end

end
  