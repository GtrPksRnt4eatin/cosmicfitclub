class TwilioVideo < Sinatra::Base

  post '/' do
  	Slack.webhook("Video Webhook", JSON.pretty_generate params)
  	status 204
  	""
  end

end
  