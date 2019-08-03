class EventCheckin < Sequel::Model

  many_to_one :event
  many_to_one :customer
  many_to_one :session, :class => :EventSession
  many_to_one :ticket, :class => :EventTicket

  def to_token
    { :id => self.id, :customer => self.customer.to_token, :session => self.session.to_token }
  end

end