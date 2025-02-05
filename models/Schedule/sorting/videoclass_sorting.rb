require 'date'

module Scheduling

  def Scheduling::get_sorted_virtual
    from    = Date.today.to_time
    to      = from + (7*24*60*60)
    classes = get_classitems_between(from,to)
    classes.reject!  { |x| x[:staff_id] == 106 }  # id106 == Cosmic Loft
    classes.reject!  { |x| x[:location][:id] != 3 } # id3 == Video Site
    #events  = get_eventsessions_between(from,to)
    #rentals = get_rentals_between(from,to)
    #items   = events + classes + rentals
    items   = classes 
    items   = items.sort_by { |x| x[:starttime] }
    { :earlier_today   => items.select { |x| (Date.today.to_time..(Time.now+(5*60))).cover? x[:endtime] },
      :happening_now   => items.select { |x| ((x[:starttime]-(5*60))..(x[:endtime]-(5*60))).cover? Time.now },
      :later_today     => items.select { |x| ((Time.now+(5*60))..(Date.today+1).to_time).cover? x[:starttime] },
      :later_this_week => items.select { |x| (Date.today+1).to_time < x[:starttime] }.group_by { |x| x[:day] },
      :flat_list       => items,
      :by_day          => items.group_by{ |x| x[:day] }
    }
  end

  def Scheduling::flat_list(from,to)
    classes = get_classitems_between(from,to)
    events  = get_eventsessions_between(from,to)
    rentals = get_rentals_between(from,to)
    items   = events + classes + rentals
    items.sort_by { |x| x[:starttime] }
  end

  def Scheduling::flat_virtual(from,to)
    classes = get_classitems_between(from,to)
    classes.reject!  { |x| x[:staff_id] == 106 }  # id106 == Cosmic Loft
    classes.reject!  { |x| x[:location][:id] != 3 } # id3 == Video Site
    classes.sort_by  { |x| x[:starttime] }
  end

end