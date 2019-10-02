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
  	list = Facebook.event_list.map(&:to_json)
    "[#{list.join(',')}]"
  end

end