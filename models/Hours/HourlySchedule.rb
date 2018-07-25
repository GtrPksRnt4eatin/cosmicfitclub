class HourlySchedule < Sequel::Model

  plugin :json_serializer
  
  many_to_one :Customer
  many_to_one :Staff

end