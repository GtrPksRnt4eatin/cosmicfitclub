class ScheduleRoutes < Sinatra::Base

  get '/:from/:to' do
    from = Time.parse(params[:from])
    to = Time.parse(params[:to])
    classes = get_classitems_between(from,to)
    events  = get_eventsessions_between(from,to)
    items = events + classes
    items = items.group_by { |x| x[:day] }
    arr = []
    items.each { |k,v| arr << { :day => k, :occurrences => v.sort_by { |x| x[:starttime] } } }
    JSON.generate arr.sort_by { |x| x[:day] }
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
          :headcount => ClassOccurrence.get_headcount( sched.classdef.id, (sched.teachers[0].id or 'TBA'), starttime.to_time.iso8601 ),
          :capacity => sched.capacity,
          :exception => ClassException.find( :classdef_id => sched.classdef.id, :original_starttime => starttime.to_time.iso8601 )
        }
      end
    end
    items
  end

  def get_eventsessions_between(from,to)
    items = EventSession.between(from,to)
    items.map do |i| 
      { :type => 'eventsession',
        :day => Date.strptime(i.start_time).to_s,
        :starttime => Time.parse(i.start_time),
        :endtime => Time.parse(i.end_time),
        :title => i.title,
        :event_title => i.event.name,
        :event_id => i.event_id,
        :multisession_event => i.event.sessions.count > 1
      }
    end
  end


  def get_private_events_between(from,to)

  end

  def get_classexceptions_between(from,to)
    items = ClassException.between(from,to)
  end

  def get_classoccurrences_between(from,to)

  end

end