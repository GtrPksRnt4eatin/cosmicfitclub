class EventTicket < Sequel::Model

  plugin :json_serializer

  many_to_one :event
  many_to_one :customer
  many_to_one :recipient, :class => :Customer, :key => :purchased_for
  one_to_many :checkins, :class => :EventCheckin, :key => :ticket_id

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

  def to_json(args)
    super( :include => { :checkins => {}, :customer => { :only => [ :id, :name, :email ] }, :purchased_for => { :only => [ :id, :name, :email ] }, :event => { :only => [ :id, :name ] } } )
  end

end
