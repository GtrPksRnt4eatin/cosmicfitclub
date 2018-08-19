class EventCheckin < Sequel::Model

  many_to_one :event
  many_to_one :customer
  many_to_one :session, :class => :EventSession
  many_to_one :ticket, :class => :EventTicket

end