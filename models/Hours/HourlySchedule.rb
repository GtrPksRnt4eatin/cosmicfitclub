class HourlySchedule < Sequel::Model

  plugin :json_serializer
  
  many_to_one :customer
  many_to_one :staff

end