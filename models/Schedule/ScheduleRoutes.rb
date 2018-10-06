require 'icalendar'

class ScheduleRoutes < Sinatra::Base

  get '/ics' do
    attachment(filename = 'CosmicCalendar.ics', disposition = :attachment)
    ScheduleRoutes::schedule_as_ical(params[:from], params[:to])
  end

  get '/:from/:to' do
    from = Time.parse(params[:from])
    to = Time.parse(params[:to])
    classes  = get_classitems_between(from,to)
    events   = get_eventsessions_between(from,to)
    rentals = get_rentals_between(from,to)
    items = events + classes + rentals
    items = items.group_by { |x| x[:day] }
    arr = []
    items.each { |k,v| arr << { :day => k, :occurrences => v.sort_by { |x| x[:starttime] } } }
    JSON.generate arr.sort_by { |x| x[:day] }
  end

  def ScheduleRoutes::schedule_as_ical(from,to)
    ical = Icalendar::Calendar.new
    EventSession.between(from,to).map(&:to_ical_event).each    { |evt| ical.add_event(evt) }
    ClassdefSchedule.all.map(&:to_ical_event).each             { |evt| ical.add_event(evt) }
    ClassOccurrence.between(from,to).map(&:to_ical_event).each { |evt| ical.add_event(evt) }
    ical.to_ical
  end  

  def get_classitems_between(from,to)
    items = []
    ClassdefSchedule.all.each do |sched|
      sched.get_occurences(from,to).each do |starttime|
        items << { 
          :type => 'classoccurrence',
          :day => Date.strptime(starttime.to_time.iso8601).to_s,
          :starttime => starttime.to_time, 
          :endtime => sched.end_time,
          :title => sched.classdef.name,
          :classdef_id => sched.classdef.id,
          :sched_id => sched.id,
          :instructors => sched.teachers,
          :headcount => ClassOccurrence.get_headcount( sched.classdef.id, ( sched.teachers[0].nil? ? 0 : sched.teachers[0].id ), starttime.to_time.iso8601 ),
          :capacity => sched.capacity,
          :exception => ClassException.find( :classdef_id => sched.classdef.id, :original_starttime => starttime.to_time.iso8601 ).try(:details)
        }
      end
    end
    items
  end

  def get_eventsessions_between(from,to)
    EventSession.between(from,to).map(&:schedule_details_hash).compact

    # do |i|
    ##  next nil if i.event.nil? 
    #  { :type => 'eventsession',
    #    :day => Date.strptime(i.start_time).to_s,
    ##   :starttime => Time.parse(i.start_time),
    #    :endtime => Time.parse(i.end_time),
    #    :title => i.title,
    #    :event_title => i.event.name,
    #    :event_id => i.event_id,
    #    :multisession_event => i.event.sessions.count > 1
    #  }
    #end.compact
  end


  def get_rentals_between(from,to)
    items = Rental.between(from,to)
    items.map do |i|
      { :type => 'private',
        :day => Date.strptime(i.start_time.to_s).to_s,
        :starttime => Time.parse(i.start_time.to_s),
        :endtime => i.end_time,
        :title => i.title
      }
    end
  end

  def get_classexceptions_between(from,to)
    items = ClassException.between(from,to)
  end

  def get_classoccurrences_between(from,to)
 
  end



end