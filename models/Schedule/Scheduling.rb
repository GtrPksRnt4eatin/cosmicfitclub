module Scheduling

  def Scheduling::get_all_between(from,to)
    classes  = new_get_classitems_between(from,to)
    events   = get_eventsessions_between(from,to)
    rentals  = get_rentals_between(from,to)
    items = events + classes + rentals
    items.group_by { |x| x[:day] }.sort.to_h
  end

  def Scheduling::get_classitems_between(from,to)
    occurrences = ClassOccurrence.all_between(from,to).map(&:schedule_details_hash)
    scheduled   = ClassdefSchedule.all.map { |s| s.get_occurrences_with_exceptions(from,to) }.flatten
    return ( scheduled + occurrences ).uniq { |x| { :classdef_id => x[:classdef_id] || x[:classdef][:id], :starttime => x[:starttime] } }
  end

  def Scheduling::get_eventsessions_between(from,to)
    EventSession.between(from,to).map(&:schedule_details_hash).compact
  end

  def Scheduling::get_rentals_between(from,to)
    Rental.between(from,to).map(&:schedule_details_hash).compact
  end

end