require 'koala'

module Facebook
  
  Facebook::API = Koala::Facebook::API.new(ENV['FACEBOOK_PAGE_TOKEN'])

  def Facebook.event_list
  	Facebook::API.get_connections("me", "events")
  end

end

class FacebookRoutes < Sinatra::Base

  get '/event_list' do
  	content_type :json
  	Facebook.event_list.to_json
  end

end