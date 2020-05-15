class TwilioVideo < Sinatra::Base

  post '/' do
  	Slack.webhook("Video Webhook", params.to_json);
  	status 204
  	""
  end

end
  