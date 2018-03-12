class EventPrice < Sequel::Model

  plugin :json_serializer

  many_to_one :event
  many_to_one :sessions, :class => :EventSession

end