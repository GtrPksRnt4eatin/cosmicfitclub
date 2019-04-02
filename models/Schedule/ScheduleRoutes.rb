require 'icalendar'

class ScheduleRoutes < Sinatra::Base

  get '/ics' do
    from = params[:from] || Date.today.beginning_of_month
    to   = params[:to]   || Date.today.end_of_month
    attachment(filename = 'CosmicCalendar.ics', disposition = :attachment)
    ScheduleRoutes::schedule_as_ical(from, to)
  end

  get '/csv' do
    content_type 'application/csv'
    from  = Date.today.beginning_of_week
    to    = Date.today.end_of_week 
    attachment "#{from} - #{to} Schedule.csv"
    items = ScheduleRoutes::get_all_between(from, to)
    CSV.generate do |csv|
      csv << ['COSMIC FIT CLUB SCHEDULE', from.to_s, to.to_s]
      csv << []
      items.each do |day,item|
        csv << ['',day,'']
        item.each do |line|
          csv << [ DateTime.parse(line['starttime']).try(:strftime,'%l:%M %p'), line['endtime'].try(:strftime,'%l:%M %p'), line['title'], line['instructors'], line.to_json ]
        end
      end
    end
  end

  get '/:from/:to' do
    from = Time.parse(params[:from])
    to = Time.parse(params[:to])
    items = ScheduleRoutes::get_all_between(from,to)
    arr = []
    items.each { |k,v| arr << { :day => k, :occurrences => v.sort_by { |x| x[:starttime] } } }
    JSON.generate arr.sort_by { |x| x[:day] }
  end

  get '/conflicts' do
    
  end

  def ScheduleRoutes::schedule_as_ical(from,to)
    ical = Icalendar::Calendar.new
    EventSession.between(from,to).map(&:to_ical_event).each    { |evt| ical.add_event(evt) }
    ClassdefSchedule.all.map(&:to_ical_event).each             { |evt| ical.add_event(evt) }
    ClassOccurrence.between(from,to).map(&:to_ical_event).each { |evt| ical.add_event(evt) }
    ical.to_ical
  end

  def ScheduleRoutes::get_all_between(from,to)
    classes  = get_classitems_between(from,to)
    events   = get_eventsessions_between(from,to)
    rentals = get_rentals_between(from,to)
    items = events + classes + rentals
    items.group_by { |x| x[:day] }
  end  

  def get_classitems_between(from,to)
    items = ClassOccurrence.between(from,to).map(&:schedule_details_hash)
    ClassdefSchedule.all.each do |sched|
      details = sched.schedule_details_hash
      sched.get_occurrences(from,to).each do |starttime|
        exception = ClassException.find( :classdef_id => sched.classdef.id, :original_starttime => starttime.to_time.iso8601 ).try(:details)
        start = exception ? exception[:starttime].to_time : starttime.to_time
        items << {
          :day => Date.strptime(start.iso8601).to_s,
          :starttime => start,
          :endtime   => start + sched.duration_sec, 
          :headcount => ClassOccurrence.get_headcount( sched.classdef.id, ( sched.teachers[0].nil? ? 0 : sched.teachers[0].id ), start.iso8601 ),
          :exception => exception
        }.merge!(details)
      end
    end
    items
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

  def get_classoccurrences_between(from,to)
 
  end



end