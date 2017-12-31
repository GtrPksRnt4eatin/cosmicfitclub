class CustomerRoutes < Sinatra::Base

  get '/' do
    content_type :json
    Customer.all.to_json
  end

  get '/:id' do
    content_type :json
    custy = Customer[params[:id].to_i]
    halt 404 if custy.nil?
    custy.to_json(:include=>:payment_sources)
  end

  post '/:id/info' do
    data = JSON.parse request.body.read
    custy = Customer[params[:id]] or halt 404
    custy.update( 
      :name => data["name"], 
      :email => data["email"],
      :phone => data["phone"],
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

  get '/:id/payment_sources' do
    custy = Customer[params[:id]] or halt 404
    JSON.generate custy.payment_sources
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
    p data
    JSON.generate data
  end

  get '/:id/wallet' do
    content_type :json
    custy = Customer[params[:id]] or halt 404
    wallet = custy.wallet
    return '{ id: 0 }' if wallet.nil?
    hsh = {}
    hsh[:shared] = wallet.shared?
    hsh[:shared_with] = wallet.customers.reject{ |x| x.id == custy.id }.map { |c| { :id => c.id, :name => c.name } }
    hsh[:id] = wallet.id
    hsh[:pass_balance] = wallet.pass_balance
    hsh[:pass_transactions] = wallet.transactions
    hsh[:pass_transactions] = hsh[:pass_transactions].inject([]) do |tot,el|
      el = el.to_hash
      el[:running_total] = tot.last.nil? ? el[:delta] : tot.last[:running_total] + el[:delta]
      tot << el 
    end

    return hsh.to_json
  end

  get '/:id/status' do
    content_type :json
    custy = Customer[params[:id]] or halt 404
    { :membership => custy.subscription.nil? ? { :id => 0, :name => 'None' } : custy.subscription.plan,
      :passes => custy.num_passes
    }.to_json
  end

  get '/:id/reservations' do
    custy = Customer[params[:id]] or halt 404
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
    custy = Customer[params[:id]] or halt 404
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
    custy.add_passes( params[:value], params[:reason] );
  end

end