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
    data = JSON.parse params[:payload]
    case data["actions"][0]["action_id"]
    when "teacher_promo"
      staff = Staff[data["actions"][0]["selected_option"]["value"]] or halt(404, "staff not found");
      PostStaffPromo.perform_async(staff)
    when "class_promo"
      classdef = ClassDef[data["actions"][0]["selected_option"]["value"]] or halt(404, "class not found");
      PostClassPromo.perform_async(classdef)
    when "timeslot_promo"
      timeslot = ClassdefSchedule[data["actions"][0]["selected_option"]["value"]] or halt(404, "timeslot not found");
      PostTimeslotPromo.perform_async(timeslot)
    when "event_promo"
      event = Event[data["actions"][0]["selected_option"]["value"]] or halt(404, "event not found");
      PostEventPromo.perform_async(event)
    end
  end

  post '/weeklySchedule' do
    date = Date.parse(params["text"]) rescue Date.today
    PostWeeklySchedule.perform_async(date)
    status 200
    "Generating Promo... Please Wait!"
  end

  post '/classesPromo' do
    class_ids = ClassDef.list_active_and_current.map(&:id)
    PostClassesPromo.perform_async(class_ids)
    "Generating Promo... Please Wait!"
  end

  post '/dailyPromo' do
    date = Date.parse(params["text"]) rescue Date.today
    PostDailyPromo.perform_async(date)
    "Generating Promo... Please Wait!"
  end

  post '/eventPromo' do
    event_list = Event::future.map { |x| [x.id, x.name] }
    client = Slack::Web::Client.new({:ca_file=>ENV["SSL_CERT_FILE"]})
    client.chat_postMessage(slackbot_static_select("Select an Event", event_list, "event_promo"))
    status 204
  end

  post '/classPromo' do
    class_list = ClassDef::list_active_and_current.map { |x| [x.id, x.name] }
    client = Slack::Web::Client.new({:ca_file=>ENV["SSL_CERT_FILE"]})
    client.chat_postMessage(slackbot_static_select("Select a Class", class_list, "class_promo"))
    status 204
  end

  post '/timeslotPromo' do
    timeslot_list = ClassdefSchedule.all.map { |x| [ x.id, "#{x.classdef.name} #{x.simple_meeting_time_description_with_staff(false)}" ] }
    client = Slack::Web::Client.new({:ca_file=>ENV["SSL_CERT_FILE"]})
    msg = slackbot_static_select("Select a Timeslot", timeslot_list, "timeslot_promo")
    p msg
    p client.chat_postMessage(slackbot_static_select("Select a Timeslot", timeslot_list, "timeslot_promo"))
    status 204
  end

  post '/teacherPromo' do
    teacher_list = Staff::active_teacher_list.map { |x| [x.id, x.name] }
    client = Slack::Web::Client.new({:ca_file=>ENV["SSL_CERT_FILE"]})
    client.chat_postMessage(slackbot_static_select("Select a Teacher", teacher_list, "teacher_promo"))
    status 204
  end

  post '/schedulePromos' do
    PostSchedPromos.perform_async()
    "Generating Promos... Please Wait!"
  end

  post '/upcomingEventsPromo' do
    PostUpcomingEventsPromo.perform_async()
    "Generating Promo... Please Wait!"
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
    client = Slack::Web::Client.new({:ca_file=>ENV["SSL_CERT_FILE"]})
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

class SlackUploader
  include SuckerPunch::Job
  def upload(promos)
    client = Slack::Web::Client.new({:ca_file=>ENV["SSL_CERT_FILE"]})
    promos.each do |p|
      client.files_upload(
        channels: '#promotional_materials',
        as_user: false,
        file: Faraday::UploadIO.new(p[:io], p[:mime] ),
        title: "#{p[:title]}",
        filetype: p[:ext],
        filename: "#{p[:title]}.#{p[:ext]}"
      )
    end
  end
end

class GeneratePayPalReport
  include SuckerPunch::Job
  def perform(start,finish)
    csv = PayPalSDK::list_transactions_csv(start,finish)
    client = Slack::Web::Client.new({:ca_file=>ENV["SSL_CERT_FILE"]})
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

class PostCustomPromo
  include SuckerPunch::Job
  def perform(elements, options)
    promo = BubblePoster::generate_a4(elements, options)
    client = Slack::Web::Client.new({:ca_file=>ENV["SSL_CERT_FILE"]})
    client.files_upload(
      channels: '#promotional_materials',
      as_user: false,
      file: Faraday::UploadIO.new(promo.path, "image/jpeg"),
      title: "#{date.to_s} Promo",
      filetype: 'jpg',
      filename: "#{date.to_s}_promo.jpg"
    )
  rescue => err
    Slack.err("PostCustomPromo Error", err)
    p err
  end
end

class PostWeeklySchedule < SlackUploader
  def perform(date)
    date ||= Date.today
    promo = SchedulePoster4x6::generate(date)
    upload([{:title=> "SchedulePoster_#{date}", :io=>promo.path, :mime=>"image/jpeg"}])
  rescue => err
    Slack.err("PostCustomPromo Error", err)
  end
end

class PostClassesPromo < SlackUploader
  def perform(class_ids)
    promo = ClassesPoster_4x6::generate("", class_ids)
    upload([{:title=> "ClassesPoster_#{Date.today}", :io=>promo.path, :mime=>"image/jpeg", :ext=>'jpg'}])
  rescue => err
    Slack.err("PostClassesPromo Error", err)
  end
end

class PostDailyPromo
  include SuckerPunch::Job
  def perform(date)
    promos = DailyPromo::generate_for_bot(date)
    client = Slack::Web::Client.new({:ca_file=>ENV["SSL_CERT_FILE"]})
    promos.each_with_index do |promo,i|
      client.files_upload(
        channels: '#promotional_materials',
        as_user: false,
        file: Faraday::UploadIO.new(promo.path, "image/jpeg"),
        title: "#{date.to_s} Promo#{i}",
        filetype: 'jpg',
        filename: "#{date.to_s}_promo#{i}.jpg"
      )
    end
  rescue => err
    Slack.err("PostDailyPromo Error", err)
    p err
  end
end 

class PostEventPromo < SlackUploader
  def perform(event)
    promos = EventPoster.generate_for_bot(event)
    upload( promos.map { |p| { :title=>p[:title], :io=>p[:img].path, :mime=>"image/jpeg", :ext=>'jpg'} })
  rescue => err
    Slack.err("PostEventPromo Error", err)
  end
end

class PostUpcomingEventsPromo
  include SuckerPunch::Job
  def perform()
    promos = UpcomingEvents.generate_for_bot
    client = Slack::Web::Client.new({:ca_file=>ENV["SSL_CERT_FILE"]})
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
    Slack.err("PostUpcomingEventsPromo Error", err)
  end
end

class PostClassPromo
  include SuckerPunch::Job
  def perform(classdef)
    promos = ClassPromo.generate_for_bot(classdef)
    client = Slack::Web::Client.new({:ca_file=>ENV["SSL_CERT_FILE"]})
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
    Slack.err("PostClassPromo Error", err)
  end
end

class PostStaffPromo
  include SuckerPunch::Job
  def perform(staff)
    promos = StaffPoster.generate_for_bot(staff)
    client = Slack::Web::Client.new({:ca_file=>ENV["SSL_CERT_FILE"]})
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
    Slack.err("PostStaffPromo Error", err)
  end
end

class PostTimeslotPromo
  include SuckerPunch::Job
  def perform(sched)
    promos = SchedulePromo.generate_for_bot(sched)
    client = Slack::Web::Client.new({:ca_file=>ENV["SSL_CERT_FILE"]})
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
    Slack.err("PostTimeslotPromo Error", err)
  end
end

class PostSchedPromos
  include SuckerPunch::Job
  def perform()
    promos = SchedulePromo.generate_all_for_bot
    client = Slack::Web::Client.new({:ca_file=>ENV["SSL_CERT_FILE"]})
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
    Slack.err("PostStaffPromo Error", err)
  end
end
