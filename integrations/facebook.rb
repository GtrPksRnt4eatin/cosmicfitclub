require 'rest-client'
require 'json'

module Facebook
  API_VERSION = "v21.0"
  BASE_URL    = "https://graph.facebook.com/#{API_VERSION}"
  PAGE_TOKEN  = ENV['FB_PROMO_TOKEN']
  PAGE_ID     = ENV['FB_PAGE_ID']
  IG_USER_ID  = ENV['IG_USER_ID']
  APP_ID      = ENV['FB_PROMO_ID']
  APP_SECRET  = ENV['FB_PROMO_SECRET']

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

  # Post a photo story to the Facebook page
  # image_url must be a publicly accessible URL
  def self.post_fb_story(image_url)
    page_id = PAGE_ID || "me"
    post("#{page_id}/photo_stories", { url: image_url })
  end

  # Post a video story to the Facebook page.
  # video_url must be a publicly accessible URL.
  # Uses the 3-phase resumable upload: start -> transfer -> finish, then publish to stories.
  def self.post_fb_video_story(video_url)
    page_id = PAGE_ID || "me"

    # Download the video to a tempfile so we know its size
    video_data = RestClient.get(video_url).body
    file_size  = video_data.bytesize

    # Phase 1: start
    start_resp = post("#{page_id}/videos", {
      upload_phase: "start",
      file_size:    file_size
    })
    upload_session_id = start_resp["upload_session_id"]
    raise "FB video upload start failed: #{start_resp.inspect}" unless upload_session_id

    # Phase 2: transfer (single chunk — whole file)
    tmpfile = Tempfile.new(["fb_video", ".mp4"])
    tmpfile.binmode
    tmpfile.write(video_data)
    tmpfile.rewind

    transfer_resp = RestClient.post(
      "https://graph-video.facebook.com/#{API_VERSION}/#{page_id}/videos",
      {
        access_token:      PAGE_TOKEN,
        upload_phase:      "transfer",
        upload_session_id: upload_session_id,
        start_offset:      0,
        video_file_chunk:  tmpfile
      }
    )
    transfer_json = JSON.parse(transfer_resp.body)
    raise "FB video transfer failed: #{transfer_json.inspect}" if transfer_json["error"]

    # Phase 3: finish (unpublished)
    finish_resp = post("#{page_id}/videos", {
      upload_phase:      "finish",
      upload_session_id: upload_session_id,
      published:         false
    })
    video_id = finish_resp["video_id"]
    raise "FB video finish failed: #{finish_resp.inspect}" unless video_id

    # Publish to story
    post("#{page_id}/video_stories", { video_id: video_id })
  ensure
    tmpfile&.close
    tmpfile&.unlink
  end

  # Keep old name as alias
  def self.post_story(image_url)
    post_fb_story(image_url)
  end

  # Post a photo story to the connected Instagram Business account.
  # Two-step process: create media container, then publish it.
  # image_url must be a publicly accessible URL (HTTPS, JPEG/PNG).
  def self.post_ig_story(image_url)
    raise "IG_USER_ID not configured" unless IG_USER_ID

    # Step 1: create the media container
    container = post("#{IG_USER_ID}/media", {
      image_url:  image_url,
      media_type: "STORIES"
    })
    creation_id = container["id"]
    raise "Failed to create IG media container: #{container.inspect}" unless creation_id

    # Step 2: publish the container
    result = post("#{IG_USER_ID}/media_publish", { creation_id: creation_id })
    result
  end

  # Post a video story to the connected Instagram Business account.
  # video_url must be a publicly accessible URL.
  def self.post_ig_video_story(video_url)
    raise "IG_USER_ID not configured" unless IG_USER_ID

    # Step 1: create the video media container
    container = post("#{IG_USER_ID}/media", {
      video_url:  video_url,
      media_type: "STORIES"
    })
    creation_id = container["id"]
    raise "Failed to create IG video media container: #{container.inspect}" unless creation_id

    # Step 2: poll until the container is ready, then publish
    max_attempts = 10
    max_attempts.times do |i|
      status = get("#{creation_id}", { fields: "status_code" })
      case status["status_code"]
      when "FINISHED"
        return post("#{IG_USER_ID}/media_publish", { creation_id: creation_id })
      when "ERROR", "EXPIRED"
        raise "IG video container failed: #{status.inspect}"
      else
        sleep(i < 3 ? 3 : 5)
      end
    end
    raise "IG video container timed out after #{max_attempts} attempts"
  end

  # Return the token permissions so you can verify story-related scopes are granted
  def self.debug_token
    get("me", { fields: "id,name" })
  end

  def self.token_permissions
    response = RestClient.get(
      "https://graph.facebook.com/debug_token",
      params: {
        input_token:  PAGE_TOKEN,
        access_token: "#{APP_ID}|#{APP_SECRET}"
      }
    )
    JSON.parse(response.body)["data"]
  rescue RestClient::ExceptionWithResponse => e
    JSON.parse(e.response.body)
  end
end

class FacebookRoutes < Sinatra::Base

  get '/event_list' do
    content_type :json
    Facebook.event_list.to_json
  end

  # Returns token identity + permissions — useful for verifying scopes
  get '/token_info' do
    content_type :json
    {
      identity:    Facebook.debug_token,
      permissions: Facebook.token_permissions
    }.to_json
  end

  # POST /integrations/facebook/story
  # Body: { "image_url": "https://..." }
  # Posts a photo story to the Facebook page
  post '/story' do
    content_type :json
    data = JSON.parse(request.body.read)
    result = Facebook.post_fb_story(data['image_url'])
    result.to_json
  end

  # POST /integrations/facebook/ig_story
  # Body: { "image_url": "https://..." }
  # Posts a photo story to the connected Instagram Business account
  post '/ig_story' do
    content_type :json
    data = JSON.parse(request.body.read)
    result = Facebook.post_ig_story(data['image_url'])
    result.to_json
  rescue => e
    status 500
    { error: e.message }.to_json
  end

  # POST /integrations/facebook/ig_video_story
  # Body: { "video_url": "https://..." }
  post '/ig_video_story' do
    content_type :json
    data = JSON.parse(request.body.read)
    result = Facebook.post_ig_video_story(data['video_url'])
    result.to_json
  rescue => e
    status 500
    { error: e.message }.to_json
  end

  # POST /integrations/facebook/ig_video_story_for_sched/:id
  # Posts the schedule's stored video to the IG connected account as a story
  post '/ig_video_story_for_sched/:id' do
    content_type :json
    sched = ClassdefSchedule[params[:id]]  or halt(404, { error: 'Schedule not found' }.to_json)
    halt(422, { error: 'No video on this schedule' }.to_json) unless sched.video_url
    result = Facebook.post_ig_video_story(sched.video_url)
    result.to_json
  rescue => e
    status 500
    { error: e.message }.to_json
  end

  # POST /integrations/facebook/fb_video_story_for_sched/:id
  # Posts the schedule's stored video to the Facebook page as a story
  post '/fb_video_story_for_sched/:id' do
    content_type :json
    sched = ClassdefSchedule[params[:id]]  or halt(404, { error: 'Schedule not found' }.to_json)
    halt(422, { error: 'No video on this schedule' }.to_json) unless sched.video_url
    result = Facebook.post_fb_video_story(sched.video_url)
    result.to_json
  rescue => e
    status 500
    { error: e.message }.to_json
  end

end