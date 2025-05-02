require 'sinatra/cross_origin'

require_relative '../../extensions/JwtAuth.rb'

class CustomerRoutes < Sinatra::Base
  
  ################################### CONFIG ####################################

  register Sinatra::Auth
  use JwtAuth

  configure do
    enable :cross_origin
  end

  before do
    cache_control :no_store
    origin_ok = ['https://video.cosmicfitclub.com', 'https://localhost:3000'].include? request.env["HTTP_ORIGIN"]
    response.headers['Access-Control-Allow-Origin'] = request.env["HTTP_ORIGIN"] if origin_ok
    response.headers['Access-Control-Allow-Credentials'] = 'true'
  end

  ################################### CONFIG ####################################
  
  #################################### LISTS ####################################

  get '/' do
    content_type :json
    Customer.all.to_json
  end

  get '/list' do
    content_type :json
    Customer.list.to_json
  end

  #################################### LISTS ####################################

  #################################### CRUD #####################################

  get '/:id' do
    content_type :json
    params[:id].to_i > 0 or pass
    custy = Customer[params[:id].to_i]
    halt 404 if custy.nil?
    halt(403, JSON.generate("Not Authorized to View Another Customer")) if session[:user_id].nil?
    halt(403, JSON.generate("Not Authorized to View Another Customer")) if session[:customer_id] != params[:id].to_i unless User[session[:user_id]].has_role?( ['admin', 'frontdesk'] )
    return custy.to_json(:include=>:payment_sources)
  end

  delete '/:id' do
    custy = Customer[params[:id]] or halt(404, "Cant Find Customer")
    dependencies = custy.linked_objects
    halt(409, dependencies.join("\r\n") ) unless dependencies.count == 0
    custy.delete
  end

  get '/:id/fulldetails' do
    custy = Customer[params[:id]] or halt(404,"Can't Find Customer")
    { :info            => custy,
      :subscriptions   => JSON.parse(custy.subscriptions.to_json( include: :plan )),
      :tickets         => EventTicket.select_all(:event_tickets).select_append(:name).join( :events, id: :event_id ).where( :customer_id => custy.id ).all.map(&:values),
      :wallet          => JSON.parse(custy.wallet.to_json( include: :transactions )),
      :reservations    => JSON.parse(custy.reservations.to_json( include: :occurrence )),
      :payments        => custy.payments,
      :training_passes => custy.training_passes,
      :password        => custy.password_set?,
      :waivers         => custy.waivers
    }.to_json
  end
 
  post '/:id/info' do
    data = JSON.parse request.body.read
    custy = Customer[params[:id]] or halt 404
    custy.update(
      :name    => data["name"],
      :email   => data["email"],
      :phone   => data["phone"],
      :address => data["address"]
    )
    status 204
  end

  get '/:id/staffinfo' do
    content_type :json
    custy = Customer[params[:id].to_i] or halt(404,'Customer Not Found')
    return custy.staff_info.to_json
  end

  get '/:id/status' do
    content_type :json
    custy = Customer[params[:id].to_i] or halt 404
    { :membership => custy.subscription.nil? ? { :id => 0, :name => 'None' } : custy.subscription.plan,
      :passes => custy.num_passes
    }.to_json
  end

  get '/:id/payments' do
    content_type :json
    custy = Customer[params[:id].to_i] or halt(404, "Customer Not Found")
    custy.payments.sort_by{ |x| x[:timestamp] }.to_json
  end

  post '/misc_payment' do
    content_type :json
    payment = CustomerPayment[params[:payment_id].to_i] or halt(404, "Payment Not Found")
    payment.send_notification
  end

  post '/:id/merge_into/:merge_id' do
    custy1 = Customer[params[:id]] or halt(404, "Cant Find Customer")
    custy1.merge_with(params[:merge_id])
    status 200
  end

  #################################### CLASS PASSES ####################################

  post '/:id/add_passes' do
    custy = Customer[params[:id]] or halt(404, "Cant Find Customer")
    custy.add_passes( params[:value], params[:reason], "" );
  end

  post '/:id/use_passes' do
    custy = Customer[params[:id]] or halt(404, "Cant Find Customer")
    transaction = custy.rem_passes( params[:num_passes], params[:reason], "");
    return transaction.id.to_json
  end

  post '/:id/transfer' do
    sugar_daddy        = Customer[params[:from]] or halt( 404, "Couldn't Find Customer" )
    minnie_the_moocher = Customer[params[:to]]   or halt( 404, "Couldn't Find Customer" )
    sugar_daddy.transfer_passes_to( minnie_the_moocher.id, params[:amount] ) or halt 403
    status 204
  end

  get '/:id/class_passes' do
    custy = Customer[params[:id]] or halt 404
    custy.num_passes.to_json
  end

  get '/:id/wallet' do
    content_type :json
    custy = Customer[params[:id]] or halt 404
    wallet = custy.wallet
    return '{ id: 0 }' if wallet.nil?
    hsh = {}
    hsh[:id] = wallet.id
    hsh[:shared] = wallet.shared?
    hsh[:shared_with] = wallet.customers.reject{ |x| x.id == custy.id }.map { |c| { :id => c.id, :name => c.name } }
    hsh[:pass_balance] = wallet.fractional_balance.to_f
    hsh[:pass_transactions] = wallet.history 
    return hsh.to_json
  end

  get '/:id/transaction_history' do
    custy = Customer[params[:id]] or halt 404
    data = {
      :pass_transactions => custy.pass_transactions,
      :membership_uses => custy.membership_uses 
    }
    data.to_json
  end

  get '/:id/reservations' do
    custy = Customer[params[:id].to_i] or halt 404
    reservations = custy.reservations.map(&:to_token)
    JSON.generate reservations.sort_by { |r| r[:starttime] }.reverse
  end

  #################################### CLASS PASSES ####################################

  ################################### POINT RENTALS ####################################

  get '/:id/upcoming_rentals' do
    GroupReservation.upcoming_for(params[:id].to_i).to_json
  end
  
  ################################### POINT RENTALS ####################################

  #################################### SUBSCRIPTION ####################################

  get '/:id/subscription' do
    content_type :json
    custy = Customer[params[:id]] or halt(404)
    custy.subscription.to_json
  end

  get '/:id/subscriptions' do
    custy = Customer[params[:id]] or halt(404)
    custy.subscriptions.map do |sub|
      { :subscription_id => sub.id,
        :plan_name       => sub.plan.try(:name) || "???",
        :num_uses        => sub.uses.count,
        :began_on        => sub.began_on
      }.merge sub
    end.to_json
  end

  get '/:id/membership' do
    content_type :json
    custy = Customer[params[:id]] or halt 404
    return '{ "plan": { "name": "None" } }' if custy.subscription.nil?
    return '{ "plan": { "name": "None" } }' if custy.subscription.deactivated
    data = { :membership => JSON.parse( custy.subscription.to_json(:include => [ :plan ])) , :details => custy.subscription.stripe_info }
    JSON.generate data
  end

  get '/:id/membership_history' do
    content_type :json
    custy = Customer[params[:id]] or halt 404
    custy.subscriptions.to_json
  end

  #################################### SUBSCRIPTION ####################################

  #################################### RELATIONSHIP ####################################

  post '/:id/add_child' do
    custy = Customer[params[:id]] or halt 404
    child = Customer[params[:child_id]] or halt 404
    custy.add_child(child)
    status 204
  end

  post '/:id/add_partner' do
    custy = Customer[params[:id]] or halt 404
    partner = Customer[params[:partner_id]] or halt 404
    custy.share_wallet_with(partner)
    status 204
  end

  get '/:id/family' do
    content_type :json
    custy = Customer[params[:id].to_i] or halt 404
    { :parents  => JSON.parse(custy.parents.to_json( :only => [:id, :name] )),
      :children => JSON.parse(custy.children.to_json( :only => [:id, :name] ))
    }.to_json
  end

  #################################### RELATIONSHIP ####################################

  ################################## PAYMENT SOURCES ###################################

  get '/:id/payment_sources' do
    custy = Customer[params[:id]] or halt 404
    JSON.generate custy.payment_sources
  end

  get '/:id/stripe_details' do
    content_type :json
    custy = Customer[params[:id]] or halt 404
    return nil if custy.stripe_id.nil?
    JSON.generate StripeMethods.get_customer(custy.stripe_id)
  end

  post('/:customer_id/cards', :self_or => 'frontdesk') do
    custy = Customer[params[:customer_id]] or halt(404, "Cant Find Customer")
    StripeMethods::create_stripe_customer(custy, params[:token])      if custy.stripe_id.nil?
    StripeMethods::add_card(params[:token][:id], custy.stripe_id) unless custy.stripe_id.nil?
  end

  post('/:customer_id/cards/set_default', :self_or => 'frontdesk') do
    custy = Customer[params[:customer_id]] or halt( 404, 'Customer Not Found')
    custy.stripe_id                        or halt( 404, 'Customer Has No Stripe Account')
    StripeMethods::set_default_card( custy.stripe_id, params[:source_id] ) 
  end

  delete('/:customer_id/cards/:source_id', :self_or=> 'frontdesk') do
    custy = Customer[params[:customer_id]] or halt( 404, 'Customer Not Found')
    custy.stripe_id                        or halt( 404, 'Customer Has No Stripe Account')
    StripeMethods::remove_card( custy.stripe_id, params[:source_id] )
  end

  ################################## PAYMENT SOURCES ###################################

  ###################################### WAIVER ########################################

  get '/:id/waiver.svg' do
    content_type 'image/svg+xml'
    custy = Customer[params[:id]] or halt(404, "Cant Find Customer")
    custy.waiver.try(:signature)  or halt(404, "Waiver Not Signed" ) 
  end

  get '/waiver' do
    content_type 'image/svg+xml'
    custy = Customer[session[:customer_id]]
    halt(401, "Not Signed In")     if custy.nil?
    halt(404, "Waiver Not Signed") if custy.waiver.nil?
    return custy.waiver.signature
  end

  post( '/waiver', :auth => 'user' ) do
    custy = Customer[session[:customer_id]]
    custy.add_waiver( Waiver.create(:signature => request.body.read ) )
    return 204
  end

  get '/waivers/:waiver_id' do
    content_type 'image/svg+xml'
    waiver = Waiver[params[:waiver_id]] or halt(404, "Cant Find Waiver")
    return waiver.signature
  end

  delete '/waivers/:waiver_id' do
    waiver = Waiver[params[:waiver_id]] or halt(404, "Cant Find Waiver")
    waiver.delete
    return 204
  end

  ###################################### WAIVER ########################################

  get '/:id/event_history' do
    custy = Customer[params[:id]] or halt(404, "Cant Find Customer")
    query = %{
      SELECT
        event_tickets.*,
        events.name,
        events.starttime
        FROM event_tickets 
        LEFT JOIN events ON events.id = event_id
        WHERE customer_id = ?;
    }
    tics = $DB[query, [params[:id]]].all
    data = {
      :past => tics.select { |x| x[:starttime].nil? ? true : x[:starttime] < Time.now },
      :upcoming => tics.select { |x| x[:starttime].nil? ? false : x[:starttime] >= Time.now }
    }
    data.to_json
  end

  error do
    Slack.err( 'Customer Route Error', env['sinatra.error'] )
    'An Error Occurred.'
  end

end
