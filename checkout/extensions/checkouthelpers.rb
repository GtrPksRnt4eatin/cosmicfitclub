$SWIPELISTENERS = []

module Sinatra
  module CheckoutHelpers

    def buy_plan
      data = JSON.parse request.body.read
      custy = Customer.get_from_token( data['token'] )
      halt 409 if ( custy.plan != nil ) && ( !custy.plan.deactivated ) ## Already Has A Plan, Log in to Update instead
      custy.add_subscription( data['plan_id'] )
      Slack.website_purchases("[\##{custy.id}] #{custy.name} (#{custy.email}) became a member!")
      status 204
    end

    def buy_pack
      data = JSON.parse request.body.read
      custy = logged_in? ? customer : Customer.get_from_email( data['token']['email'], data['token']['card']['name'] )
      custy.buy_pack_card( data['pack_id'], data['token'] )
      Slack.website_purchases("[\##{ custy.id }] #{ custy.name } (#{ custy.email }) bought a #{ Package[data['pack_id']].name }.")
      status 204
    end

    def buy_pack_precharged
      custy = Customer[params[:customer_id]] or halt 403
      custy.buy_pack_precharged( params[:pack_id], params[:payment_id] )
      Slack.website_purchases("[\##{custy.id}] #{custy.name} (#{custy.email}) bought a #{Package[params[:pack_id]].name} precharged.")
    end

    def buy_training
      data = JSON.parse request.body.read
      custy = Customer.get_from_token( data['token'] )
      custy.buy_training( data['num_hours'], 2, data['trainer'] )
      Slack.website_purchases("[\##{custy.id}] #{custy.name} (#{custy.email}) bought personal training.")
      status 204
    end

    def buy_event
      data = JSON.parse request.body.read
      custy = logged_in? ? customer : Customer.get_from_email( data['token']['email'], data['token']['card']['name'] )
      custy.send_new_account_email if custy.login.nil?
      eventname = Event[data['metadata']['event_id']].name
      data['metadata']['name'] = data['token']['card']['name']
    
      data['multiplier'] ||= 1

      if data['multiplier'] > 1 then
        description = "[\##{custy.id}] #{custy.name} (#{custy.email}) bought #{data['multiplier']} $#{data['total_price']/data['multiplier'].to_i/100} tickets for #{eventname}."
      else
        description = "[\##{custy.id}] #{custy.name} (#{custy.email}) bought a $#{data['total_price']/100} ticket for #{eventname}."
      end

      charge = StripeMethods::charge_card(data['token']['id'], data['total_price'], data['token']['email'], description, data['metadata']);

      payment = CustomerPayment.create(:customer => custy, :stripe_id => charge.id, :amount => data['total_price'], :reason => description, :type => 'new card')
      
      data['multiplier'].to_i.times do 
        EventTicket.create( 
          :customer            => custy, 
          :event_id            => data['event_id'], 
          :included_sessions   => data['included_sessions'], 
          :price               => data['total_price'] / data['multiplier'].to_i,
          :event_price_id      => data['selected_price'] ? data['selected_price']['id'] : nil,
          :customer_payment_id => payment.id
        )
      end
      status 204
    end

    def buy_event_precharged
      params[:multiplier] ||= 1

      params[:multiplier].to_i.times do 
        EventTicket.create(
          :customer_id         => params[:customer_id],
          :event_id            => params[:event_id],
          :included_sessions   => params[:included_sessions],
          :price               => params[:total_price] / params[:multiplier].to_i,
          :customer_payment_id => params[:payment_id], 
          :event_price_id      => params[:price_id]
        )
        status 204
      end
    end

    def register_event
      data = JSON.parse request.body.read
      custy = logged_in? ? customer : Customer.get_from_email( data['email'], "");
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
