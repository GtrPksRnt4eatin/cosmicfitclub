class EventPass < Sequel::Model

  many_to_one :customer
  many_to_one :ticket, :class => :EventTicket, :key => :ticket_id
  many_to_one :session, :class => :EventSession, :key => :session_id

  def EventPass.generate_from_old_schema
    EventTicket.all.each do |tic|
      tic.included_sessions.each do |sess|
      	checkin = EventCheckin.find( :ticket_id => tic.id, :session_id => sess, :customer_id => tic.recipient.id )
        EventPass.create( :ticket => tic, :session_id => sess, :customer_id => tic.recipient.id, :checked_in => checkin.try(:timestamp) )
      end
    end
  end

  def checkin
    self.update( :checked_in => Time.now )
  end

  def checkout
    self.update( :checked_in => nil )
  end

  def start_time
    self.session.start_time
  end

  def event
    self.session.event
  end

  def to_token
    { :id => self.id, :session => self.session.to_token, :customer => self.customer.to_token, :checked_in => self.checked_in } 
  end

  def attendance_hash
    { :id => self.id, :session_id => self.session_id, :ticket => self.ticket.try(:to_token), :customer => self.customer.try(:to_token), :checked_in => self.checked_in }
  end

end
