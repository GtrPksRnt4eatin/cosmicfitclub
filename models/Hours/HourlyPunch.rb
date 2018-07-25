class HourlyPunch < Sequel::Model

  plugin :json_serializer

  many_to_one :Customer
  many_to_one :Staff
  many_to_one :HourlyTask

  

end