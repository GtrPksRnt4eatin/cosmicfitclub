class EventPrice < Sequel::Model

  many_to_one :event
  many_to_one :sessions, :class => :EventSession

end