class EventPrice < Sequel::Model

  many_to_one :event
  many_to_one :sessions, :class => :EventSession
  one_to_many :event_tickets

end