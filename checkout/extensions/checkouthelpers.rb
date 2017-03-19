module Sinatra
  module CheckoutHelpers

    def buy_plan
      data = JSON.parse request.body.read
      customer = Customer.get_from_token( data['token'] )
      halt 409 if customer.plan != nil                       ## Already Has A Plan, Log in to Update instead
      customer.add_subscription( data['plan_id'] )
      status 204
    end

    def buy_pack
      data = JSON.parse request.body.read
      customer = Customer.get_from_token( data['token'] )
      customer.buy_pack( data['pack_id'] )
      status 204
    end

    def buy_training
      data = JSON.parse request.body.read
      customer = Customer.get_from_token( data['token'] )
      customer.buy_training( data['num_hours'], 1, data['trainer'] )
      status 204
    end

    def buy_event
      data = JSON.parse request.body.read
      customer = Customer.get_from_token( data['token'] )


      if data.total_price==0 then
        ( status 400; return; ) unless logged_in?
        require 'pry'; binding.pry
        customer.add_ticket
      end
      ( status 400; return; ) if !logged_in && data.total_price==0
      ( )
      #new_custy = Customer.is_new? data['token']['email']

      #customer = Customer.get_from_token( data['token'] )
      #customer.send_new_account_email if new_custy
      #customer.buy_event(data['event_id'])
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
  
  end
end