class EventTicket < Sequel::Model
  
  plugin :pg_array_associations

  many_to_one :event
  many_to_one :customer
  many_to_one :recipient, :class => :Customer, :key => :purchased_for
  one_to_many :checkins, :class => :EventCheckin, :key => :ticket_id
  pg_array_to_many :sessions, :class => :EventSession, :key => :included_sessions

  def generate_code
    rand(36**8).to_s(36)
  end

  def after_create
    super
    update( :code => generate_code )
    model = {
      :event_name => event.name,
      :event_date => event.starttime.strftime('%a %m/%d'),
      :event_time => event.starttime.strftime('%I:%M %p'),
      :code => code
    }
    Mail.event_purchase(customer.email, model)
  end

  def sessions_string
    return DateTime.parse(sessions[0].start_time).strftime('%a %m/%d') if sessions.length < 2 
    sessions.map { |x| "#{x.title} - #{DateTime.parse(x.start_time).strftime('%a %m/%d')} #{DateTime.parse(x.start_time).strftime('%a %m/%d')}" }.join("\r\n")
  end

  def to_json(options = {})
    super( :include => { :checkins => {}, :customer => { :only => [ :id, :name, :email ] }, :recipient => { :only => [ :id, :name, :email ] }, :event => { :only => [ :id, :name ] } } )
  end

  def to_details_json
    self.to_json( :include => { :checkins => {}, :customer => { :only => [ :id, :name, :email ] }, :recipient => { :only => [ :id, :name, :email ] }, :event => { :only => [ :id, :name ] } } )
  end

  def split(recipient_id, session_ids)
    return "Customer Doesn't Exist" if Customer[recipient_id].nil?
    return "Sessions Not Included On Ticket" unless (session_ids - self.included_sessions).empty?
    EventTicket.create( 
      :customer_id        => self.customer_id,
      :event_id          => self.event_id,
      :included_sessions => session_ids,
      :code              => self.code + '_split',
      :price             => 0,
      :stripe_payment_id => self.stripe_payment_id,
      :purchased_for     => recipient_id
    )
    self.update( :included_sessions => (self.included_sessions - session_ids) )
  end

end
