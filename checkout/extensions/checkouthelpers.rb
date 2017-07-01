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
      custy = logged_in? ? customer : Customer.get_from_email( data['token']['email'], data['token']['card']['name'] )
      custy.buy_pack_card( data['pack_id'], data['token'] )
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
      custy = logged_in? ? customer : Customer.get_from_email( data['token']['email'], data['token']['card']['name'] )
      custy.send_new_account_email if custy.login.nil?
      eventname = Event[data['metadata']['event_id']].name
      data['metadata']['name'] = data['token']['card']['name']
      charge = StripeMethods::charge_card(data['token']['id'], data['total_price'], data['token']['email'], eventname, data['metadata']);
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

    def charge_card
      custy = Customer[params[:customer]]
      params[:email] = custy.email if params[:email].nil?
      params[:metadata] ||= {}
      description = "#{custy.name} purchased #{params[:description]}"  
      charge = StripeMethods::charge_card(params[:token], params[:amount], params[:email], description, params[:metadata])
      CustomerPayment.create( :customer => custy, :stripe_id => charge.id, :amount => params[:amount], :reason => params[:description]).to_json
    end

    def card_swipe
      tok = Stripe::Token.retrieve
      halt 400 if tok.nil?
      @swipe_token = tok
    end

    def wait_for_swipe
      stream do |out|
        while !out.closed? do
          return @swipe_token.to_json unless @swipe_token.nil?
          sleep(0.5) 
        end
      end
    end
  
  end
end