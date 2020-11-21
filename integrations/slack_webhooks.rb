require 'sucker_punch'
require 'slack-ruby-client'

Slack.configure do |config|
  config.token = ENV['SLACK_TOKEN']
end

def slackbot_static_select(title, opts, action_id)
  {
    :channel => "promotional_materials",
    :blocks => [
      {
        :type => "actions",
        :elements => [
          {
            :type => "static_select",
            :placeholder => {
              :type => "plain_text",
              :text => title
            },
            :options => opts.map { |opt|
              {
                :text => {
                  :type => "plain_text",
                  :text => opt[1]
                },
                :value => opt[0].to_s
              }
            },
            :action_id => action_id
          }
        ]
      }
    ]
  }
end

class SlackBot < Sinatra::Base

  post '/interactivity' do
    p JSON.pretty_print params
  end

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

  post '/classPromo' do
    class_list = ClassDef::list_active_and_current.map { |x| [x.id, x.name] }
    client = Slack::Web::Client.new
    client.chat_postMessage(slackbot_static_select("Select a Class", class_list, "class_promo"))
    status 204
  end

  post '/schedulePromo' do
    sched_list = ClassdefSchedule.all.map { |x| [x.id, "#{x.classdef.name} #{description_line simple_meeting_time_description_with_staff(false)}"] }
    p sched_list
    client = Slack::Web::Client.new
    client.chat_postMessage(slackbot_static_select("Select a Class Schedule", sched_list, "sched_promo"))
    status 204
  end

  post '/teacherPromo' do
    teacher_list = Staff::active_teacher_list.map { |x| [x.id, x.name] }
    client = Slack::Web::Client.new
    client.chat_postMessage(slackbot_static_select("Select a Teacher", teacher_list, "teacher_promo"))
    status 204
  end

  post '/paypal' do
    now = DateTime.now
    match = /(\d{4}-\d{2}-\d{2}) (\d{4}-\d{2}-\d{2})/.match(params["text"])
    start = match.nil? ? DateTime.new(now.year,now.month-1,1,0,0,0,now.zone) : match[1]
    finish = match.nil? ? DateTime.new(now.year,now.month,1,0,0,0,now.zone) : match[2]
    GeneratePayPalReport.perform_async(start,finish)
    "Generating Report... Please Wait!"
  end

  post '/payroll' do
    last_period = Payroll::get_last_period
    match  = /(\d{4}-\d{2}-\d{2}) (\d{4}-\d{2}-\d{2})/.match(params["text"])
    start  = match.nil? ? last_period[:from] : DateTime.parse(match[1])
    finish = match.nil? ? last_period[:to]   : DateTime.parse(match[2])
    GeneratePayrollReport.perform_async(start,finish)
    "Generating Report... Please Wait!"
  end

  error do
    Slack.err( 'Slackbot Error', env['sinatra.error'] )
    'An Error Occurred.'
  end

end

class GeneratePayrollReport
  include SuckerPunch::Job
  def perform(start,finish)
    csv = Staff::payroll_csv(start,finish)
    client = Slack::Web::Client.new
    client.files_upload(
      channels: 'payroll',
      as_user: true,
      file: Faraday::UploadIO.new(csv.to_io, 'text/csv', "Payroll Report #{start} #{finish}.csv"),
      title: "Payroll Report",
      filetype: 'csv',
      filename: "Payroll Report #{start} #{finish}.csv"
    )
  rescue => err
    Slack.err("GeneratePayrollReport Error", err)
  end
end

class GeneratePayPalReport
  include SuckerPunch::Job
  def perform(start,finish)
    csv = PayPalSDK::list_transactions(start,finish)
    client = Slack::Web::Client.new
    client.files_upload(
      channels: 'payroll',
      as_user: true,
      file: Faraday::UploadIO.new(csv.to_io, 'text/csv', "Paypal Report #{start} #{finish}.csv"),
      title: "Paypal Report",
      filetype: 'csv',
      filename: "Paypal Report #{start} #{finish}.csv"
    )
  rescue => err
    Slack.err("GeneratePaypalReport Error", err)
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

class PostClassPromo
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