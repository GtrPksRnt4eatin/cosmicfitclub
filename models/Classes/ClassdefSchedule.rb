class ClassdefSchedule < Sequel::Model
  
  plugin :pg_array_associations
  pg_array_to_many :teachers, :key => :instructors, :class => :Staff

  many_to_one :classdef, :key => :classdef_id, :class => :ClassDef
  one_to_many :exceptions, :key => :class_schedule_id, :class => :ClassException

  def ClassdefSchedule.get_all_occurrences(from,to)
    items = []
    ClassdefSchedule.all.each do |sched|
      sched.get_occurrences(from, to).each do |starttime|
        exception = ClassException.find( :classdef_id => sched.classdef.id, :original_starttime => starttime.to_time.iso8601 )
        items << { 
          :day => Date.strptime(starttime.to_time.iso8601).to_s,
          :starttime => starttime,
          :endtime =>  starttime + ( sched.end_time - sched.start_time ),
          :title => sched.classdef.name,
          :classdef_id => sched.classdef.id,
          :sched_id => sched.id,
          :instructors => exception.try(:teacher) ? [exception.teacher] : sched.teachers,
          :exception => exception.try(:full_details)
        }
      end
    end
    items
  end

  def ClassdefSchedule.get_class_page_rankings
    items = []
    from = DateTime.now
    to = from.next_day(7)
    ClassdefSchedule.all.each do |sched|
      sched.get_occurrences(from,to).each do |starttime|
        items << { :starttime => starttime, :classdef => sched.classdef.to_token }
      end
    end
    items.sort_by!{ |x| x[:starttime] }
    items.uniq!{ |x| x[:classdef] }
  end

  def get_occurrences(from,to)
    return [] if rrule.nil?
    return [] if start_time.nil?
    from = Time.parse(from) if from.is_a? String
    to = Time.parse(to) if to.is_a? String
    IceCube::Schedule.new(start_time) do |sched|
      sched.add_recurrence_rule IceCube::Rule.from_ical(rrule)
    end.occurrences_between(from,to)
  end

  def get_occurrences_with_exceptions(from,to)
    get_occurrences(from,to).map do |starttime|
      exception  =  ClassException.find( :classdef_id => self.classdef.id, :original_starttime => starttime.to_time.iso8601 )
      occurrence = ClassOccurrence.find( :classdef_id => self.classdef_id, :starttime          => starttime.to_time.iso8601 )
      {  :sched_id   => self.id, 
         :starttime  => starttime,
         :classdef   => self.classdef.to_token,
         :teachers   => self.teachers.map(&:to_token),
         :occurrence => occurrence.try(:to_hash),
         :exception  => exception.try(:full_details),
      }
    end
  end

  def get_occurrences_with_exceptions_merged(from,to)
    get_occurrences_with_exceptions(from,to).map do |occ|
      next occ if occ[:exception].nil?
      next nil if occ[:exception][:changes][:cancelled]
      occ[:teachers]  = [occ[:exception][:changes][:sub]]     unless occ[:exception][:changes][:sub].nil?
      occ[:starttime] = occ[:exception][:changes][:starttime] unless occ[:exception][:changes][:starttime].nil?
      occ.delete(:exception)
      next occ      
    end
  end

  def to_ical_event
    ical = Icalendar::Event.new 
    ical.dtstart = DateTime.parse(Date.today.to_s + "T" + start_time.to_s)
    ical.duration = "P#{Time.at(duration_sec).utc.hour}H#{Time.at(duration_sec).utc.min}M#{Time.at(duration_sec).utc.sec}S"
    ical.rrule = rrule
    ical.summary = "#{classdef.name} w/ #{teachers.map(&:name).join(', ')}"
    ical
  end

  def schedule_details_hash
    { :type        => 'classoccurrence',
      :sched_id    => self.id,
      :duration    => duration_sec,
      :classdef_id => self.classdef.id,
      :title       => self.classdef.name,
      :instructors => self.teachers.map(&:to_token),
      :capacity    => self.capacity
    }
  end

  def get_exception_dates
    exceptions
  end

  def rrule_english;   IceCube::Rule.from_ical(rrule).to_s              end
  def start_time_12hr; Time.parse(start_time.to_s).strftime("%I:%M %P") rescue start_time end
  def end_time_12hr;   Time.parse(end_time.to_s).strftime("%I:%M %P")   rescue end_time   end

  def description_line
    "#{classdef.name} w/ #{teachers.map(&:name).join(", ")} #{rrule_english} @ #{start_time_12hr}"
  end

  def full_description
    "#{classdef.name} w/ #{teachers.map(&:name).join(", ")} #{rrule_english} #{start_time_12hr} - #{end_time_12hr}"
  end

  def details_hash
    { :id => id,
      :classdef   => classdef.to_token,
      :teachers   => teachers.map(&:to_token),
      :rrule      => rrule_english,
      :start_time => start_time_12hr,
      :capacity   => capacity
    }
  end

  def duration_sec
    end_time - start_time
  end

end