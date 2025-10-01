class EventRoutes < Sinatra::Base

  before do
    cache_control :no_store
  end

  #################################### EVENT LISTS ##############################

  get '/' do
    content_type :json
    JSON.generate Event::list_future
  end

  get '/future_all' do
    content_type :json
    JSON.generate Event::list_future_all
  end

  get '/past' do
    content_type :json
    JSON.generate Event::list_past
  end

  get '/list' do
    content_type :json
    Event::short_list
  end

  #################################### EVENT LISTS ##############################

  ###################################### EVENTS #################################

  post '/' do
    content_type :json
    if Event[params[:id]].nil?
      event = Event.create(
        name:             params[:name],
        subheading:       params[:subheading],
        description:      params[:description], 
        details:          params[:details],
        poster_lines:     params[:poster_lines],
        starttime:        params[:starttime], 
        image:            params[:image],
        mode:             params[:mode],
        hidden:           params[:hidden],
        registration_url: params[:registration_url]
      )
    else
      event = Event[params[:id]]
      event.update_fields(params, [ :name, :subheading, :description, :details, :poster_lines, :starttime, :mode, :hidden, :registration_url ] )
      event.update( :image => params[:image] ) unless params[:image].nil?
    end
    status 200
    event.to_json
  end
  
  get '/:id' do
    content_type :json
    event = Event[params[:id]] or halt(404,'event not found')
    data = event.full_detail
    JSON.generate data
  end

  get '/:id/admin_detail' do
    content_type :json
    event = Event[params[:id]] or halt(404,'event not found')
    data = event.admin_detail
    JSON.generate data
  end

  delete '/:id' do
    event = Event[params[:id]] or halt(404,"Event Not Found")
    event.can_delete?          or halt(409,"#{event.linked_objects.join(', ')}")
    Event[params[:id]].delete
    status 204; {}.to_json
  end
  
  post '/:id/duplicate' do
    Event::duplicate(params[:id])
  end

  ###################################### EVENTS #################################

  ################################### EVENT PROPS ###############################

  get '/:id/image_url' do
    event = Event[params[:id]] or halt(404,'event not found')
    event.image_url
  end

  post '/:id/image' do
    event = Event[params[:id]] or halt(404,'event not found')
    event.update( :image => params[:image] )
    status 204; {}.to_json
  end

  post '/:id/image_wide' do
    event = Event[params[:id]] or halt(404,'event not found')
    event.wide_image.update( :image => params[:image] ) if event.wide_image
    event.update( :wide_image => StoredImage.create( :image => params[:image] ) ) unless event.wide_image
    status 204; {}.to_json 
  end

  post '/:id/short_url' do
    event = Event[params[:id]] or halt(404,'event not found')
    ShortUrl.where( :short_path => params[:short_url]).delete
    event.short_url.update( :short_path => params[:short_url] ) if event.short_url
    event.update( :short_url => ShortUrl.create( :short_path => params[:short_url], :long_path => "/checkout/event/" + params[:id] ) ) unless event.short_url
    status 204; {}.to_json
  end

  get '/:id/thumbnail' do
    event = Event[params[:id]] or halt 404
    halt(404,"Image Not Found") if event.image.nil?
    img = event.get_image(:small)
    halt 404 if img.nil? 
    content_type img.mime_type
    send_file img.download.path
  end

  ################################### EVENT PROPS ###############################

  ################################## EVENT SESSIONS #############################

  get '/:id/sessions' do
    content_type :json
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

  ################################## EVENT SESSIONS #############################

  ################################### EVENT PRICES ##############################

  get '/:id/prices' do
    event = Event[params[:id]] or halt(404,'event not found')
    event.prices.to_json
  end

  get '/:id/prices/available' do
    event = Event[params[:id]] or halt(404,'event not found')
    event.available_prices.to_json
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

  ################################### EVENT PRICES ##############################

  ################################## EVENT TICKETS ##############################

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
    tic.split( recipient.id, params[:session_ids].map { |x| x.to_i } )
    status 204
  end

  post '/tickets/:tic_id/move' do
    tic = EventTicket[params[:tic_id]]          or halt(404, "Couldn't Find Event Ticket")
    event = Event[params[:event_id]]            or halt(404, "Couldn't Find Event")
    tic.update( :event => event )
    status 204
  end

  delete '/tickets/:id' do
    ticket = EventTicket[params[:id]] or halt(404, "Couldn't Find Ticket")
    ticket.delete
    status 204
  end

  ################################## EVENT TICKETS ##############################

  ################################## EVENT PASSES ###############################

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

  ################################## EVENT PASSES ###############################
  
  ############################## EVENT COLLABORATIONS ###########################

  post '/collabs' do
    content_type :json
    if collab = EventCollaboration.find( :event_id=>params[:event_id], :customer_id=>params[:customer_id] ) then
      collab.update( :percentage=>params[:percentage], :notify=>params[:notify] )
    else
      EventCollaboration.create( :event_id=>params[:event_id], :customer_id=>params[:customer_id], :percentage=>params[:percentage], :notify=>params[:notify] )
    end.to_json
  end

  delete '/collabs/:id' do
    collab = EventCollaboration[params[:id]] or halt(404, "Couldn't Find EventCollaboration")
    collab.delete
  end

  ############################## EVENT COLLABORTIONS ###########################

  get '/:id/attendance' do
    content_type :json
    event = Event[params[:id]] or halt(404, "Event Not Found")
    event.attendance.to_json
  end

  get '/:id/attendance2' do
    content_type :json
    event = Event[params[:id]] or halt(404, "Event Not Found")
    event.attendance2.to_json
  end

  get '/:id/sheet2drive' do
    content_type :json
    event = Event[params[:id]] or halt(404, "Event Not Found")
    { :url => Sheets::create_event_sheet(params[:id].to_i) }.to_json
  end

  get '/:id/attendance.csv' do
    content_type 'application/csv'
    event = Event[params[:id]] or halt(404, "Event Not Found")
    attachment "#{event.name} Attendance.csv"
    event.attendance_csv
  end

  get '/:id/accounting' do
    content_type :json
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

  error do
    Slack.err( 'Event Route Error', env['sinatra.error'] )
    'An Error Occurred.'
  end

end
