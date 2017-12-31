class ClassdefSchedule < Sequel::Model
  
  plugin :pg_array_associations
  pg_array_to_many :teachers, :key => :instructors, :class => :Staff

  many_to_one :classdef, :key => :classdef_id, :class => :ClassDef

  def get_occurences(from,to)
    return [] if rrule.nil?
    return [] if start_time.nil?
    from = Time.parse(from) if from.is_a? String
    to = Time.parse(to) if to.is_a? String
    IceCube::Schedule.new(start_time) do |sched|
      sched.add_recurrence_rule IceCube::Rule.from_ical(rrule)
    end.occurrences_between(from,to)
  end

  def ClassdefSchedule.get_all_occurrences(from,to)
    items = []
    ClassdefSchedule.all.each do |sched|
      sched.get_occurences(from, to).each do |starttime|
        items << { 
          :day => Date.strptime(starttime.to_time.iso8601).to_s,
          :starttime => starttime,
          :endtime =>  starttime + ( sched.end_time - sched.start_time ),
          :title => sched.classdef.name,
          :classdef_id => sched.classdef.id,
          :sched_id => sched.id,
          :instructors => sched.teachers
        }
      end
    end
    items
  end

end