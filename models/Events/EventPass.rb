class EventPass < Sequel::Model

  many_to_one :customer
  many_to_one :ticket, :class => :EventTicket, :key => :ticket_id
  many_to_one :session, :class => :EventSession, :key => :session_id

end