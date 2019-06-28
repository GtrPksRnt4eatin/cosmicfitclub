class EventTicket < Sequel::Model
  
  plugin :pg_array_associations

  ###################### ASSOCIATIONS #####################

  many_to_one :event
  many_to_one :customer
  many_to_one :recipient,     :class => :Customer,     :key => :purchased_for
  many_to_one :eventprice,    :class => :EventPrice,   :key => :event_price_id
  one_to_many :checkins,      :class => :EventCheckin, :key => :ticket_id
  one_to_many :passes,        :class => :EventPass,    :key => :ticket_id
  pg_array_to_many :sessions, :class => :EventSession, :key => :included_sessions

  ###################### ASSOCIATIONS #####################

  ####################### LIFE CYCLE ######################

  def after_create
    super
    self.generate_code
    self.send_email
    self.generate_passes
    self.send_notification
  rescue
  end

  ####################### LIFE CYCLE ######################

  #################### ATTRIBUTE ACCESS ###################

  def recipient
    super || self.customer
  end

  #################### ATTRIBUTE ACCESS ###################

  ################# CALCULATED PROPERTIES #################

  def get_stripe_id
    self.stripe_payment_id.to_i > 0 ? CustomerPayment[self.stripe_payment_id].stripe_id : self.stripe_payment_id
  end

  def full_payment_info
    StripeMethods::get_payment_totals(self.get_stripe_id)
  end

  #def customer_info
  #  { :id    => ( customer.id    rescue 0  ),
  #    :name  => ( customer.name  rescue "" ),
  #    :email => ( customer.email rescue "" )
  #  }
  #end

  ################# CALCULATED PROPERTIES #################

  #################### ACTION METHODS #####################

  def send_email
    Mail.event_purchase(self.customer.email, self.mailer_model)
  end

  def send_notification
    Slack.post(self.summary)
    Slack.custom(self.summary,"@b.konash") if self.event.id == 386
  end

  def generate_passes
    self.included_sessions.each do |sess_id|
      EventPass.create( :customer => self.recipient, :ticket => self, :session_id => sess_id )
    end
  end

  def generate_code
    self.update( :code=> rand(36**8).to_s(36) )
  end

  def resend_email(address=nil)
    address ||= customer.email
    Mail.event_purchase(address, self.mailer_model)
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

  #################### ACTION METHODS #####################

  ########################## VIEWS ########################
   
  def summary
    "#{self.customer.to_list_string} bought a $#{self.price.to_f/100} #{self.eventprice.title} ticket for #{self.event.name}."
  end

  def sessions_string
    return DateTime.parse(sessions[0].start_time).strftime('%a %m/%d @ %I:%M %p') if event.sessions.length < 2 
    sessions.map { |x| "#{x.title} - #{DateTime.parse(x.start_time).strftime('%a %m/%d @ %I:%M %p')}" }.join(", ")
  end

  def mailer_model
    { :event_name      => self.event.name,
      :event_date      => self.event.starttime.strftime('%a %m/%d'),
      :event_time      => self.event.starttime.strftime('%I:%M %p'),
      :sessions_string => self.sessions_string,
      :code            => self.code
    }
  end

  def to_json(options = {})
    super( :include => { :checkins => {}, :customer => { :only => [ :id, :name, :email ] }, :recipient => { :only => [ :id, :name, :email ] }, :event => { :only => [ :id, :name ] } } )
  end

  def to_details_json
    self.to_json( :include => { :checkins => {}, :customer => { :only => [ :id, :name, :email ] }, :recipient => { :only => [ :id, :name, :email ] }, :event => { :only => [ :id, :name ] } } )
  end

  ########################## VIEWS ########################

end
