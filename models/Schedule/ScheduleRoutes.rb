require 'icalendar'
require 'tzinfo'
require 'icalendar/tzinfo'
require 'sinatra/cross_origin'

class ScheduleRoutes < Sinatra::Base

    ################################### CONFIG ####################################

    register Sinatra::Auth
    use JwtAuth
  
    configure do
      enable :cross_origin
    end
  
    before do
      cache_control :no_store
      origin_ok = ['https://video.cosmicfitclub.com', 'https://localhost:3000'].include? request.env["HTTP_ORIGIN"]
      response.headers['Access-Control-Allow-Origin'] = request.env["HTTP_ORIGIN"] if origin_ok
      response.headers['Access-Control-Allow-Credentials'] = 'true'
    end
  
    ################################### CONFIG ####################################

  get '/schedule.jpg' do
    redirect StoredImage.where(:name=>"WeeklyPoster.jpg").first.image.url
  end

  get '/schedule4.jpg' do
    redirect StoredImage.where(:name=>"WeeklyPosterQuad.jpg").first.image.url
  end

  post '/generate' do
    content_type :json
    BuildSchedulePoster.perform_async(Date.today)
    {}.to_json
  end

  get '/ics' do
    from = params[:from] || Date.today.beginning_of_month
    to   = params[:to]   || (Date.today >> 2).end_of_month
    attachment(filename = 'CosmicCalendar.ics', disposition = :attachment)
    ScheduleRoutes::schedule_as_ical(from, to)
  end

  get '/csv' do
    content_type 'application/csv'
    from  = Date.today.beginning_of_week
    to    = Date.today.end_of_week.tomorrow 
    attachment "#{from} - #{to} Schedule.csv"
    items = new_get_all_between(from, to)
    CSV.generate do |csv|
      csv << ['COSMIC FIT CLUB SCHEDULE', "#{from.to_s} to #{to.to_s}" ]
      csv << []
      items.each do |day,item|
        csv << [ Date.parse(day).strftime('%A %b %e').upcase ]
        item.sort_by! { |x| x[:starttime] }
        item.each do |line|
          instructors = line[:instructors]
          instructors = instructors.map { |v| v[:name] } if instructors.is_a? Array
          instructors.join if instructors.is_a? Array
          csv << ["#{line[:starttime].strftime('%l:%M %p')} - #{line[:endtime].strftime('%l:%M %p')}", line[:title], instructors ]
        end
        csv << []
      end
    end
  end

  get '/:from/:to' do
    content_type :json
    from = Time.parse(params[:from])
    to = Time.parse(params[:to])
    items = Scheduling::get_all_between(from,to)
    arr = []
    items.each { |k,v| arr << { :day => k, :occurrences => v.sort_by { |x| x[:starttime] } } }
    JSON.generate arr.sort_by { |x| x[:day] }
  end

  get '/test/:from/:to' do
    from = Time.parse(params[:from])
    to = Time.parse(params[:to])
    items = new_get_all_between(from,to)
    arr = []
    items.each { |k,v| arr << { :day => k, :occurrences => v.sort_by { |x| x[:starttime] } } }
    JSON.generate arr.sort_by { |x| x[:day] }
  end

  get '/conflicts/:from/:to' do
    content_type :json
    Scheduling::get_potential_conflicts(from,to).to_json
  end

  get '/sorted_schedule' do
    content_type :json
    Scheduling::get_sorted_virtual.to_json
  end

  get '/loft_events/:from/:to' do
    content_type :json
    from = Time.parse(params[:from])
    to = Time.parse(params[:to])
    Calendar::get_loft_events(from,to).to_json
  end

  get '/loft_calendar/:from/:to' do
    content_type :json
    from = Time.parse(params[:from])
    to = Time.parse(params[:to])
    gcal = Calendar::get_loft_events(from,to)
    groups = GroupReservation.all_between(params[:from], params[:to]).map(&:to_admin_daypilot)
    classes = new_get_classitems_between(from,to)
    events = get_eventsessions_between(from,to)
    { gcal: gcal, groups: groups, classes: classes, events: events }.to_json
  end

  def ScheduleRoutes::schedule_as_ical(from,to)
    ical = Icalendar::Calendar.new
    ical.add_timezone TZInfo::Timezone.get("America/New_York").ical_timezone(Time.now)
    EventSession.between(from,to).map(&:to_ical_event).each         { |evt| ical.add_event(evt) }
    GroupReservation.all_between(from,to).map(&:to_ical_event).each { |evt| ical.add_event(evt) }
    ClassdefSchedule.all.map(&:to_ical_event).each                  { |evt| ical.add_event(evt) }
   #ClassOccurrence.past_between(from,to).map(&:to_ical_event).each { |evt| ical.add_event(evt) }
    ical.to_ical
  end

  def new_get_all_between(from,to)
    classes  = new_get_classitems_between(from,to)
    events   = get_eventsessions_between(from,to)
    rentals  = get_rentals_between(from,to)
    items = events + classes + rentals
    items.group_by { |x| x[:day] }.sort.to_h
  end

  def new_get_classitems_between(from,to)
    occurrences = ClassOccurrence.all_between(from,to).map(&:schedule_details_hash)
    scheduled   = ClassdefSchedule.all.map { |s| s.get_occurrences_with_exceptions(from,to) }.flatten
    return ( scheduled + occurrences ).uniq { |x| { :classdef_id => x[:classdef_id] || x[:classdef][:id], :starttime => x[:starttime] } }
  end

  def get_eventsessions_between(from,to)
    EventSession.between(from,to).map(&:schedule_details_hash).compact
  end


  def get_rentals_between(from,to)
    Rental.between(from,to).map(&:schedule_details_hash).compact
  end

  def get_classexceptions_between(from,to)
    items = ClassException.between(from,to)
  end

  error do
    Slack.err( 'Schedule Route Error', env['sinatra.error'] )
    'An Error Occurred.'
  end

end
