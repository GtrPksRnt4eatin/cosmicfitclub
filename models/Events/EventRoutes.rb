class EventRoutes < Sinatra::Base

  get '/' do
    content_type :json
    JSON.generate Event::list_future
  end

  get '/past' do
    content_type :json
    JSON.generate Event::list_past
  end

  get '/list' do
    content_type :json
    Event::short_list
  end

  get '/:id' do
    event = Event[params[:id]] or halt(404,'event not found')
    data = event.full_detail
    JSON.generate data
  end
  
  post '/' do
    if Event[params[:id]].nil?
      event = Event.create(name: params[:name], description: params[:description], details: params[:details], :starttime => params[:starttime], image: params[:image] )
    else
      event = Event[params[:id]]
      event.update_fields(params, [ :name, :description, :details, :starttime ] )
      event.update( :image => params[:image] ) unless params[:image].nil?
    end
    status 200
    event.to_json
  end

  get '/:id/sessions' do
    event = Event[params[:id]] or halt(404,'event not found')
    event.sessions.to_json
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

  get '/:id/prices' do
    event = Event[params[:id]] or halt(404,'event not found')
    event.prices.to_json
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
    EventTicket.where( :event_id => params[:id] ).all.to_json
  end

  def fmt_price(cents)
    "$ #{ ( cents.to_f / 100 ).round(2) }"
  end

  get '/:id/attendance.csv' do
    event = Event[params[:id]]
    halt 404 if event.nil?
    content_type 'application/csv'
    attachment "#{event.name} Attendance.csv"
    event.attendance_csv
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
    event = Event[params[:id]] or halt 404
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

  post'/tickets/:tic_id/assign_recipient' do
    tic = EventTicket[params[:tic_id]] or halt 404
    recipient = Customer[params[:recipient_id]] or halt 404
    tic.update( :recipient => recipient )
    status 204
  end

  post'/tickets/:tic_id/split' do
    tic = EventTicket[params[:tic_id]] or halt 404
    recipient = Customer[params[:recipient_id]] or halt 404
    p tic.split( recipient.id, params[:session_ids].map { |x| x.to_i } )
    status 204
  end

end