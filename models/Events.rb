class Event < Sequel::Model

  plugin :json_serializer

  one_to_many :tickets, :class => :EventTicket
  one_to_many :sessions, :class => :EventSession
  one_to_many :prices, :class => :EventPrice
  
  include ImageUploader[:image]

  def after_save
  	self.id
  	super
  end

  def to_json(options = {})
    val = JSON.parse super
    val['image_url'] = image.nil? ? '' : image[:original].url
    JSON.generate val
  end

  def create_session
    new_session = EventSession.create
    add_session(new_session)
    new_session
  end

  def create_price
    new_price = EventPrice.create
    add_price(new_price)
    new_price
  end

  def sessions
    super.sort
  end

end

class EventSession < Sequel::Model

  plugin :json_serializer
  
  many_to_one :event
  one_to_many :prices, :class => :EventPrice

  def start_time; val=super; val.nil? ? nil : val.iso8601 end
  def end_time;   val=super; val.nil? ? nil : val.iso8601 end

  def <=> other
    return 0 if !start_time && !other.start_time
    return 1 if !start_time
    return -1 if !other.start_time
    start_time <=> other.start_time
  end

end

class EventPrice < Sequel::Model

  plugin :json_serializer

  many_to_one :event
  many_to_one :sessions, :class => :EventSession

end

class EventTicket < Sequel::Model

  plugin :json_serializer

  many_to_one :event
  many_to_one :customer
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
    super( :include => { :checkins => {}, :customer => { :only => [ :id, :name, :email ] } } )
  end

end

class EventCheckin < Sequel::Model
  
  plugin :json_serializer

  many_to_one :event
  many_to_one :customer
  many_to_one :session, :class => :EventSession
  many_to_one :ticket, :class => :EventTicket

end

class EventRoutes < Sinatra::Base

  get '/' do
    data = Event.order(:starttime).all.map do |c|
      next if c.starttime.nil?
      next if c.starttime < Date.today.to_time
      { :id => c.id, 
        :name => c.name, 
        :description => c.description, 
        :starttime => c.starttime.nil? ? nil : c.starttime.iso8601, 
        :image_url => (  c.image.nil? ? '' : ( c.image.is_a?(ImageUploader::UploadedFile) ? c.image_url : c.image[:small].url ) ),
        :sessions => c.sessions,
        :prices => c.prices
      }
    end.compact!
    JSON.generate data
  end

  get '/:id' do
    c = Event[params[:id]]
    data = { 
      :id => c.id, 
      :name => c.name, 
      :description => c.description, 
      :starttime => c.starttime.iso8601, 
      :image_url => (  c.image.nil? ? '' : ( c.image.is_a?(ImageUploader::UploadedFile) ? c.image_url : c.image[:small].url ) ),
      :sessions => c.sessions,
      :prices => c.prices
    }
    JSON.generate data
  end
  
  post '/' do
    if Event[params[:id]].nil?
      event = Event.create(name: params[:name], description: params[:description], :starttime => params[:starttime], image: params[:image] )
    else
      require 'pry'
      binding.pry
      event = Event[params[:id]].update_fields(params, [ :name, :description, :starttime ] )
      event.update( :image => params[:image] ) unless params[:image].nil?
    end
    status 200
    event.to_json
  end

  post '/:id/sessions' do
    data = JSON.parse(request.body.read)
    session = Event[params[:id]].create_session if data['id'] == 0 
    session = EventSession[data['id']]          unless data['id'] == 0
    data.delete('id')
    session.update(data)
    session.to_json
  end 

  delete '/sessions/:id' do
    halt 404 if EventSession[params[:id]].nil?
    EventSession[params[:id]].destroy
    status 200
  end

  post '/:id/prices' do
    data = JSON.parse(request.body.read)
    price = Event[params[:id]].create_price if     data['id'] == 0 
    price = EventPrice[data['id']]          unless data['id'] == 0
    data.delete('id')
    price.update(data)
    price.to_json
  end 

  delete '/prices/:id' do
    halt 404 if EventPrice[params[:id]].nil?
    EventPrice[params[:id]].destroy
    status 200
  end

  delete '/:id' do
    halt 404 if Event[params[:id]].nil?
    Event[params[:id]].destroy
    status 200
  end

  get '/:id/attendance' do
    Event[params[:id]].tickets.to_json
  end

  get '/:id/accounting' do
    tickets = JSON.parse Event[params[:id]].tickets.to_json
    tickets.map! do |tic|
      tic['charge'] = Stripe::Charge.retrieve(tic['stripe_payment_id'])
      tic['balance_transaction'] = Stripe::BalanceTransaction.retrieve( tic['charge']['balance_transaction'] )
      tic['charge']['refunds']['data'].map! do |refund|
        refund['balance_transaction'] = Stripe::BalanceTransaction.retrieve( refund['balance_transaction'] )
      end
      tic
    end
    JSON.pretty_generate tickets
  end

  get '/:id/thumbnail' do
    event = Event[params[:id]]
    content_type event.image[:small].mime_type
    send_file event.image[:small].download.path
  end

  get '/:id/total' do
    balance = 0
    tickets = Event[params[:id]].tickets
    tickets.each do |tic|
      charge =  Stripe::Charge.retrieve(tic.stripe_payment_id)
      transaction = Stripe::BalanceTransaction.retrieve charge.balance_transaction
      balance = balance + transaction.net
      puts " + #{transaction.net}"
      puts " = #{balance}"

      charge.refunds.data.each do |refund|
        transaction = Stripe::BalanceTransaction.retrieve refund.balance_transaction
        balance = balance + transaction.net
        puts " + #{transaction.net}"
        puts " = #{balance}"
      end
    end
    ""
  end
  
  post '/tickets/:id/checkin' do
    ticket = EventTicket[params[:id]]
    halt 404 if ticket.nil?
    halt 500 unless ticket.included_sessions.include? params[:session_id].to_i
    EventCheckin.create( :ticket_id => ticket.id, :event_id => ticket.event.id, :session_id => params[:session_id], :customer_id => params[:customer_id], :timestamp => DateTime.now )
    status 204
  end

  post '/tickets/:tic_id/checkout' do
    checkin = EventCheckin[params[:id]]
    halt 404 if checkin.nil?
    checkin.destroy
    status 204
  end

end