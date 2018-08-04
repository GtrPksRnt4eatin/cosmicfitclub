class EventPass < Sequel::Model

  many_to_one :customer
  many_to_one :ticket, :class => :EventTicket, :key => :ticket_id
  

end