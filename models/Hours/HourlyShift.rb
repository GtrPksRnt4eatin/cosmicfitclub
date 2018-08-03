class HourlyShift < Sequel::Model

  plugin :json_serializer
  
  many_to_one :customer
  many_to_one :staff

  def rrule_string
    IceCube::Rule.from_ical(rrule).to_s
  end

  def range_string
    "#{ starttime.strftime('%l:%M %P') } - #{ (starttime + duration*60*60).strftime('%l:%M %P') }"
  end
  
end