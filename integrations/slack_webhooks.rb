require 'sucker_punch'
require 'slack-ruby-client'

Slack.configure do |config|
  config.token = ENV['SLACK_TOKEN']
end

class SlackBot < Sinatra::Base

  post '/dailyPromo' do
    date = Date.parse(params["text"]) || Date.today
    PostDailyPromo.perform(date)
    "Generating Promo... Please Wait!"
  end

end

class PostDailyPromo
  include SuckerPunch::Job
  def perform(date)
    promo = DailyPromo::generate_all(date)
    client = Slack::Web::Client.new
    client.files_upload(
      channels: '#promotional_materials',
      as_user: false,
      file: Faraday::UploadIO.new(promo.path, "image/jpeg"),
      title: "#{date.to_s} Promo",
      filetype: 'jpg',
      filename: "#{date.to_s}_promo.jpg"
    )
  end
end