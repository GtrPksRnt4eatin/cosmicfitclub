class EventRoutes < Sinatra::Base

  before do
    cache_control :no_store
  end

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
    content_type :json
    event = Event[params[:id]] or halt(404,'event not found')
    data = event.full_detail
    JSON.generate data
  end

  get '/:id/image_url' do
    event = Event[params[:id]] or halt(404,'event not found')
    event.image_url
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
    content_type :json    
    list = EventTicket.where( :event_id => params[:id] ).order(:created_on).all.map do |tic|
      tic.to_hash.merge( {
        :checkins  => tic.checkins.map(&:to_hash),
        :customer  => tic.customer.try(:to_list_hash),
        :recipient => tic.recipient.try(:to_list_hash),
        :event     => tic.event.to_token
      }  )
    end
    JSON.generate list
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
      tic['charge'] = Stripe::Charge.retrieve(tic.get_stripe_id)
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
      charge =  Stripe::Charge.retrieve(tic.get_stripe_id)
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

  get '/tickets/:id' do
    content_type :json
    ticket = EventTicket[params[:id]] or halt(404, "Couldn't Find Ticket")
    JSON.generate(ticket.edit_details)
  end
  
  post '/tickets/:id/checkin' do
    ticket = EventTicket[params[:id]] or halt(404, "Couldn't Find Event Ticket")
    halt 500 unless ticket.included_sessions.include? params[:session_id].to_i
    EventCheckin.create( :ticket_id => ticket.id, :event_id => ticket.event.id, :session_id => params[:session_id], :customer_id => params[:customer_id], :timestamp => DateTime.now )
    ticket.passes.find { |x| x.session_id == params[:session_id].to_i && x.customer_id == params[:customer_id].to_i }.try(:checkin)
    status 204
  end

  post '/tickets/:tic_id/checkout' do
    checkin = EventCheckin[params[:id]] or halt(404,"Couldn't Find Event Checkin")
    checkin.ticket.passes.find { |x| x.session_id == checkin.session_id && x.customer_id == checkin.customer_id && x.checked_in != nil }.try(:checkout)
    checkin.destroy
    status 204
  end

  post '/tickets/:tic_id/assign_recipient' do
    tic = EventTicket[params[:tic_id]]          or halt(404, "Couldn't Find Event Ticket")
    recipient = Customer[params[:recipient_id]] or halt(404, "Couldn't Find Recipient")
    tic.update( :recipient => recipient )
    status 204
  end

  post '/tickets/:tic_id/split' do
    tic = EventTicket[params[:tic_id]]          or halt(404, "Couldn't Find Event Ticket")
    recipient = Customer[params[:recipient_id]] or halt(404, "Couldn't Find Recipient")
    p tic.split( recipient.id, params[:session_ids].map { |x| x.to_i } )
    status 204
  end

  post '/passes' do
    EventPass.create( :ticket_id => params[:ticket_id], :session_id => params[:session_id], :customer_id => params[:customer_id] )
  end

  post '/passes/:id/checkin' do
    pass = EventPass[params[:id]] or halt(404, "Couldn't Find Event Pass")
    pass.checkin
    EventCheckin.create( :ticket_id => pass.ticket_id, :event_id => pass.session.event.id, :session_id => pass.session_id, :customer_id => pass.customer_id, :timestamp => DateTime.now )
    status 204
  end

  post '/passes/:id/checkout' do
    pass = EventPass[params[:id]] or halt(404, "Couldn't Find Event Pass")
    pass.checkout
    pass.event.checkins.find { |x| x.session_id == pass.session_id && x.customer_id == pass.customer_id }.destroy
    status 204
  end

  post '/passes/:id/transfer' do
    pass  = EventPass[params[:id]]         or halt(404, "Couldn't Find Event Pass")
    custy = Customer[params[:customer_id]] or halt(404, "Couldn't Find Customer")
    pass.update( :customer=> custy )
    pass.to_json
  end

  delete '/passes/:id' do
    pass  = EventPass[params[:id]]         or halt(404, "Couldn't Find Event Pass")
    pass.delete
  end

  error do
    Slack.err( 'Event Route Error', env['sinatra.error'] )
    'An Error Occurred.'
  end

end