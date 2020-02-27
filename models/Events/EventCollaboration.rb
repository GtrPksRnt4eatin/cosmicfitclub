
class EventCollaboration < Sequel::Model
  
  many_to_one :customer
  many_to_one :event

end