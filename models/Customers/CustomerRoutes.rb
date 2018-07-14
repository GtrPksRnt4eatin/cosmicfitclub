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

  get '/:id/fulldetails' do
    custy = Customer[params[:id]]
    { :info => custy,
      :subscriptions => JSON.parse(custy.subscriptions.to_json( include: :plan )),
      :tickets => JSON.parse(EventTicket.to_json( array: custy.tickets, include: :event )),
      :wallet => JSON.parse(custy.wallet.to_json( include: :transactions )),
      :reservations => JSON.parse(custy.reservations.to_json( include: :occurrence )),
      :payments => custy.payments,
      :training_passes => custy.training_passes
    }.to_json
    #Customer[params[:id]].to_json( include: [ :subscriptions, :passes, :tickets, :training_passes, :wallet, :reservations, :comp_tickets, :payments] )
  end

  get '/:id/subscriptions' do
    custy = Customer[params[:id]] or halt(404)
    custy.subscriptions.map do |sub|
      { :plan_name => sub.plan.name,
        :num_uses => sub.uses.count
      }.merge sub
    end.to_json
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

  get '/:id/waiver' do
    content_type 'image/svg+xml'
    return Customer[params[:id]].waiver.signature
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
    custy.add_passes( params[:value], params[:reason], "" );
  end

  post '/:id/merge_into/:merge_id' do
    custy1 = Customer[params[:id]] or halt(404, "Cant Find Customer")
    custy1.merge_with(params[:merge_id])
    status 200
  end

  delete '/:id' do
    custy = Customer[params[:id]] or halt(404, "Cant Find Customer")
    custy.delete
  end

end
