class HourlyShift < Sequel::Model
  
  many_to_one :customer
  many_to_one :staff
  many_to_one :hourly_task

  def rrule_string
    IceCube::Rule.from_ical(rrule).to_s
  end

  def range_string
    "#{ starttime.strftime('%l:%M %P') } - #{ (starttime + duration*60*60).strftime('%l:%M %P') }"
  end

  def details_hash
  	{ :staff      => self.staff.to_token,
      :recurrence => self.rrule_string,
      :range      => self.range_string,
      :task       => self.hourly_task.to_token
  	}
  end
  
end