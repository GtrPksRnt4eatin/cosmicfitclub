class EventPass < Sequel::Model

  many_to_one :customer
  many_to_one :ticket, :class => :EventTicket, :key => :ticket_id
  many_to_one :session, :class => :EventSession, :key => :session_id

  def EventPass.generate_from_old_schema
    EventTicket.all.each do |tic|
      tic.included_sessions.each do |sess|
      	checkin = EventCheckin.find( :ticket_id => tic.id, :session_id => sess, :customer_id => tic.recipient.id )
        EventPass.create( :ticket => tic, :session_id => sess, :customer_id => tic.recipient, :checked_in => checkin.try(:timestamp) )
      end
    end
  end

end