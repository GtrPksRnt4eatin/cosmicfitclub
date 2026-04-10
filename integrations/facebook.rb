require 'rest-client'
require 'json'

module Facebook
  API_VERSION = "v21.0"
  BASE_URL    = "https://graph.facebook.com/#{API_VERSION}"
  PAGE_TOKEN  = ENV['FB_PROMO_TOKEN']

  def self.get(path, params = {})
    response = RestClient.get("#{BASE_URL}/#{path}", params: params.merge(access_token: PAGE_TOKEN))
    JSON.parse(response.body)
  rescue RestClient::ExceptionWithResponse => e
    JSON.parse(e.response.body)
  end

  def self.post(path, params = {})
    response = RestClient.post("#{BASE_URL}/#{path}", params.merge(access_token: PAGE_TOKEN))
    JSON.parse(response.body)
  rescue RestClient::ExceptionWithResponse => e
    JSON.parse(e.response.body)
  end

  def self.event_list
    get("me/events")["data"] || []
  end

  # Post a text or link promotion to the page feed
  def self.post_promotion(message, link: nil)
    params = { message: message }
    params[:link] = link if link
    post("me/feed", params)
  end

  # Post a photo promotion to the page feed
  def self.post_photo(image_url, caption: nil)
    params = { url: image_url, published: true }
    params[:caption] = caption if caption
    post("me/photos", params)
  end

  # Post a photo story to the page
  def self.post_story(image_url)
    post("me/photo_stories", { url: image_url })
  end
end

class FacebookRoutes < Sinatra::Base

  get '/event_list' do
    content_type :json
    Facebook.event_list.to_json
  end

end