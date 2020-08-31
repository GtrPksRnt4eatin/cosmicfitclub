require 'sucker_punch'
require 'slack-ruby-client'

Slack.configure do |config|
  config.token = ENV['SLACK_TOKEN']
end

class SlackBot < Sinatra::Base

  post '/dailyPromo' do
    date = Date.parse(params["text"]) rescue Date.today
    PostDailyPromo.perform_async(date)
    "Generating Promo... Please Wait!"
  end

  post '/eventPromo' do
    event = Event[params["text"]] rescue Event::next
    PostEventPromo.perform_async(event)
    "Generating Promos... Please Wait!"
  end

  post '/paypal' do
    p params
    match = /(\d{4}-\d{2}-\d{2}) (\d{4}-\d{2}-\d{2})/.match(params["text"])
    halt(404) if match.nil?
    GeneratePayPalReport.perform_async(match[1],match[2])
    "Generating Report... Please Wait!"
  end

  error do
    Slack.err( 'Slackbot Error', env['sinatra.error'] )
    'An Error Occurred.'
  end

end

class GeneratePayPalReport
  include SuckerPunch::Job
  def perform(start,finish)
    transactions = PayPalSDK::list_transactions(start,finish)

  rescue => err
    Slack.err("GenerateSlackReport Error", err)
  end
end

class PostDailyPromo
  include SuckerPunch::Job
  def perform(date)
    promo = DailyPromo::generate_for_bot(date)
    client = Slack::Web::Client.new
    client.files_upload(
      channels: '#promotional_materials',
      as_user: true,
      file: Faraday::UploadIO.new(promo.path, "image/jpeg"),
      title: "#{date.to_s} Promo",
      filetype: 'jpg',
      filename: "#{date.to_s}_promo.jpg"
    )
  rescue => err
    Slack.err("PostDailyPromo Error", err)
  end
end 

class PostEventPromo
  include SuckerPunch::Job
  def perform(event)
    promos = EventPoster.generate_for_bot(event)
    client = Slack::Web::Client.new
    promos.each do |p|
      client.files_upload(
        channels: '#promotional_materials',
        as_user: false,
        file: Faraday::UploadIO.new(p[:img].path, "image/jpeg"),
        title: "#{p[:title]}",
        filetype: 'jpg',
        filename: "#{p[:title]}.jpg"
      )
    end
  rescue => err
    Slack.err("PostEventPromo Error", err)
  end
end