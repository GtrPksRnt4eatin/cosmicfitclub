class CustomerRoutes < Sinatra::Base
  register Sinatra::Auth

  before do
    cache_control :no_store
  end

  get '/' do
    content_type :json
    Customer.all.to_json
  end

  get '/list' do
    content_type :json
    Customer.list.to_json
  end

  get '/:id' do
    content_type :json
    params[:id].to_i > 0 or pass
    custy = Customer[params[:id].to_i]
    halt 404 if custy.nil?
    halt(403, 'Not Authorized to View Another Customer') if session[:user].nil?
    halt(403, 'Not Authorized to View Another Customer') if session[:customer] != custy unless session[:user].has_role?( ['admin', 'frontdesk'] )
    return custy.to_json(:include=>:payment_sources)
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
      :password        => custy.password_set?
    }.to_json
  end

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

  post '/:id/transfer' do
    sugar_daddy = Customer[params[:from]] or halt 404
    minnie_the_moocher = Customer[params[:to]] or halt 404
    sugar_daddy.transfer_passes_to( minnie_the_moocher.id, params[:amount] ) or halt 403
    status 204
  end

  post '/:id/add_child' do
    custy = Customer[params[:id]] or halt 404
    child = Customer[params[:child_id]] or halt 404
    custy.add_child(child)
    status 204
  end

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

  get '/:id/class_passes' do
    custy = Customer[params[:id]] or halt 404
    custy.num_passes.to_json
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

  get '/:id/wallet' do
    content_type :json
    custy = Customer[params[:id]] or halt 404
    wallet = custy.wallet
    return '{ id: 0 }' if wallet.nil?
    hsh = {}
    hsh[:id] = wallet.id
    hsh[:shared] = wallet.shared?
    hsh[:shared_with] = wallet.customers.reject{ |x| x.id == custy.id }.map { |c| { :id => c.id, :name => c.name } }
    hsh[:pass_balance] = wallet.pass_balance
    hsh[:pass_transactions] = wallet.history 
    return hsh.to_json
  end

  get '/:id/status' do
    content_type :json
    custy = Customer[params[:id].to_i] or halt 404
    { :membership => custy.subscription.nil? ? { :id => 0, :name => 'None' } : custy.subscription.plan,
      :passes => custy.num_passes
    }.to_json
  end

  get '/:id/family' do
    content_type :json
    custy = Customer[params[:id].to_i] or halt 404
    { :parents => JSON.parse(custy.parents.to_json( :only => [:id, :name] )),
      :children => JSON.parse(custy.children.to_json( :only => [:id, :name] ))
    }.to_json
  end

  get '/:id/reservations' do
    custy = Customer[params[:id].to_i] or halt 404
    reservations = custy.reservations.map { |res|
      { :id => res.id,
        :classname => res.occurrence.nil? ? "Orphaned Reservation" : res.occurrence.classdef.name, 
        :instructor=> res.occurrence.nil? ? "Some Teacher" : res.occurrence.teacher.name, 
        :starttime => res.occurrence.nil? ? Time.new : res.occurrence.starttime 
      } 
    }
    JSON.generate reservations.sort_by { |r| r[:starttime] }.reverse
  end

  get '/:id/transaction_history' do
    custy = Customer[params[:id]] or halt 404
    data = {
      :pass_transactions => custy.pass_transactions,
      :membership_uses => custy.membership_uses 
    }
    data.to_json
  end

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
    tics = $DB[query, params[:id]].all
    data = {
      :past => tics.select { |x| x[:starttime].nil? ? false : x[:starttime] < Time.now },
      :upcoming => tics.select { |x| x[:starttime].nil? ? false : x[:starttime] >= Time.now }
    }
    data.to_json
  end

  post '/:id/add_passes' do
    custy = Customer[params[:id]] or halt(404, "Cant Find Customer")
    custy.add_passes( params[:value], params[:reason], "" );
  end

  post '/:id/merge_into/:merge_id' do
    custy1 = Customer[params[:id]] or halt(404, "Cant Find Customer")
    custy1.merge_with(params[:merge_id])
    status 200
  end

  delete '/:id' do
    custy = Customer[params[:id]] or halt(404, "Cant Find Customer")
    dependencies = custy.linked_objects
    halt(409, dependencies.join("\r\n") ) unless dependencies.count == 0
    custy.delete
  end

  get '/:id/waiver.svg' do
    content_type 'image/svg+xml'
    custy = Customer[params[:id]] or halt(404, "Cant Find Customer")
    custy.waiver.try(:signature)  or halt(404, "Waiver Not Signed" ) 
  end

  get '/waiver' do
    content_type 'image/svg+xml'
    halt(401, "Not Signed In")     if session[:customer].nil?
    halt(404, "Waiver Not Signed") if session[:customer].waiver.nil?
    return session[:customer].waiver.signature
  end

  post( '/waiver', :auth => 'user' ) do
    session[:customer].add_waiver( Waiver.create(:signature => request.body.read ) )
    return 204
  end

  post '/:id/save_card' do
    custy = Customer[params[:id]] or halt(404, "Cant Find Customer")
    custy.update( :stripe_id => StripeMethods::create_stripe_customer(custy, params[:token]) ) if custy.stripe_id.nil?
    StripeMethods::add_card(params[:token], custy.stripe_id)                               unless custy.stripe_id.nil?
  end

  error do
    Slack.err( 'Customer Route Error', env['sinatra.error'] )
    'An Error Occurred.'
  end

end
