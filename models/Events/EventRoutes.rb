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

  get '/past' do
    data = Event.order(:starttime).all.map do |c|
      next if c.starttime.nil?
      next if c.starttime >= Date.today.to_time
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
      event = Event[params[:id]]
      event.update_fields(params, [ :name, :description, :starttime ] )
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

  def fmt_price(cents)
    "$ #{ ( cents.to_f / 100 ).round(2) }"
  end

  get '/:id/attendance.csv' do
    event = Event[params[:id]]
    halt 404 if event.nil?
    content_type 'application/csv'
    attachment "#{event.name} Attendance.csv"
    csv_string = CSV.generate do |csv|
      csv << [ "ID", "Name", "Email", "Gross", "Fee", "Refunds", "Net" ]
      net = 0
      gross = 0
      fees = 0
      refunds = 0
      event.tickets.each do |tic|
        trans = nil
        if tic.stripe_payment_id then
          charge = Stripe::Charge.retrieve(tic.stripe_payment_id)
          trans = Stripe::BalanceTransaction.retrieve charge.balance_transaction
          net = net + trans.net
          gross = gross + trans.amount
          fees = fees + trans.fee
          refund = 0
          charge.refunds.data.each do |ref|
            t = Stripe::BalanceTransaction.retrieve ref.balance_transaction
            net = net + t.net
            refund = t.net
            refunds = refunds + t.net
          end
        end
        id = tic.customer ? tic.customer.id : 0
        name = tic.customer ? tic.customer.name : ""
        email = tic.customer ? tic.customer.email : ""
        csv << [ id, name, email, "$ 0.00", "$ 0.00", "$0.00", "$ 0.00" ] unless trans
        csv << [ id, name, email, fmt_price(trans.amount), fmt_price(trans.fee), fmt_price(refund), fmt_price( trans.net + refund ) ] if trans
      end 
      csv << []
      csv << [ "Totals:", event.headcount, "", fmt_price(gross), fmt_price(fees), fmt_price(refunds), fmt_price(net) ]
    end
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

end