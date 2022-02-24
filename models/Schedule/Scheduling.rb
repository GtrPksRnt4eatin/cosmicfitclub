require_relative './sorting/videoclass_sorting.rb'

module Scheduling

  def Scheduling::get_all_sorted_by_days(from,to)
    arr   = []
    items = Scheduling::get_all_between(from,to)
    items.each { |k,v| arr << { :day => k, :occurrences => v.sort_by { |x| x[:starttime] } } }
    arr.sort_by { |x| x[:day] }
  end

  def Scheduling::get_all_virtual(from,to)
    classes  = get_classitems_between(from,to)
    events   = get_eventsessions_between(from,to)
    rentals  = get_rentals_between(from,to)
    items = events + classes + rentals
    items.select { |x| x.virtual }.group_by { |x| x[:day] }
  end

  def Scheduling::get_all_between(from,to)
    classes  = get_classitems_between(from,to)
    events   = get_eventsessions_between(from,to)
    rentals  = get_rentals_between(from,to)
    items = events + classes + rentals
    items.group_by { |x| x[:day] }
  end

  def Scheduling::get_checkin_schedule(day)
    classes = ClassOccurrence.all_between(day, day + 1).map(&:schedule_details_hash)
    events  = Scheduling::get_eventsessions_between(day, day + 1)
    rentals = Scheduling::get_rentals_between(day, day + 1)
    items = events + classes + rentals
    items.sort_by { |x| x[:starttime] }
  end

  def Scheduling::get_classitems_between(from,to)
    occurrences = ClassOccurrence.all_between(from,to).map(&:schedule_details_hash)
    scheduled   = ClassdefSchedule.all.map { |s| s.get_occurrences_with_exceptions_merged(from,to).compact }.flatten
    return ( scheduled + occurrences ).uniq { |x| { :classdef_id => x[:classdef_id] || x[:classdef][:id], :starttime => x[:starttime], :location_id => x[:location_id] } }
  end

  def Scheduling::get_eventsessions_between(from,to)
    EventSession.between(from,to).map(&:schedule_details_hash).compact
  end

  def Scheduling::get_rentals_between(from,to)
    Rental.between(from,to).map(&:schedule_details_hash).compact
  end

  def Scheduling::get_potential_conflicts(from,to)
    classes  = get_classitems_between(from,to)
    events   = get_eventsessions_between(from,to)
    rentals  = get_rentals_between(from,to)
    list = events + classes + rentals
    list = list.combination(2).map do |item1,item2|
      if item1[:starttime] < item2[:starttime] && item1[:endtime] <= item2[:starttime] then next nil end
      if item1[:starttime] >= item2[:endtime] && item1[:endtime] > item2[:endtime] then next nil end
      if item1[:type]=='classoccurrence' && item2[:type]=='classoccurrence' then next nil end
      next [item1,item2]
    end
    list.compact!
  end

end