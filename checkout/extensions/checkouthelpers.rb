module Sinatra
  module CheckoutHelpers

    def buy_plan
      data = JSON.parse request.body.read
      custy = Customer.get_from_token( data['token'] )
      halt 409 if custy.plan != nil                       ## Already Has A Plan, Log in to Update instead
      custy.add_subscription( data['plan_id'] )
      status 204
    end

    def buy_pack
      data = JSON.parse request.body.read
      custy = Customer.get_from_token( data['token'] )
      custy.buy_pack( data['pack_id'] )
      status 204
    end

    def buy_training
      data = JSON.parse request.body.read
      custy = Customer.get_from_token( data['token'] )
      custy.buy_training( data['num_hours'], 1, data['trainer'] )
      status 204
    end

    def buy_event
      data = JSON.parse request.body.read
      new_custy = Customer.is_new? data['token']['email']
      custy = Customer.get_from_token( data['token'] )
      custy.send_new_account_email if new_custy
      eventname = Event[data['metadata']['event_id']].name
      charge = StripeMethods::charge_customer(custy.stripe_id, data['total_price'], eventname, data['metadata']);
      EventTicket.create( 
        :customer => custy, 
        :event_id => data['event_id'], 
        :included_sessions => data['included_sessions'], 
        :price => data['total_price'],
        :stripe_payment_id => charge['id']
      )
      status 204
    end

    def register_event
      data = JSON.parse request.body.read
      custy = logged_in? ? customer : Customer.find( :email => data['email'] )
      if custy.nil? then
        custy = Customer.create( :email => data['email'] )
        custy.send_new_account_email
      end
      EventTicket.create( :customer => custy, :event_id => data['event_id'], :included_sessions => data['included_sessions'], :price => 0 )
      status 204
    end

    def buy_misc
      data = JSON.parse request.body.read
      token = data['token']
      p StripeMethods::find_customer_by_card(token)
    end
  
  end
end