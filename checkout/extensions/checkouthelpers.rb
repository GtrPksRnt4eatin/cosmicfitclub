$SWIPELISTENERS = []

module Sinatra
  module CheckoutHelpers

    def buy_gift_cert
      GiftCertificate::buy(params)     
    end

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

    def buy_pack_intent
      custy = customer or halt 403
      intent = StripeMethods.retreive_intent(params[:intent_id])
      payment = CustomerPayment.create(:customer => custy, :stripe_id => intent.id, :amount => intent.amount, :reason => intent.description, :type => 'intent', :tag => 'package')
      custy.buy_pack_precharged(params[:pack_id], payment.id)
      Slack.website_purchases("[\##{custy.id}] #{custy.name} (#{custy.email}) bought a #{Package[params[:pack_id]].name} with a PaymentIntent.")
      { status: 'complete' }.to_json
    end

    def donate_intent
      custy = customer or halt 403
      intent = StripeMethods.retreive_intent(params[:intent_id])
      payment = CustomerPayment.create(:customer => custy, :stripe_id => intent.id, :amount => intent.amount, :reason => intent.description, :type => 'intent', :tag => 'class')
      occurrence = ClassOccurrence.get(params[:classdef_id], params[:staff_id], params[:starttime], params[:location_id]) or halt(404) 
      reservation = occurrence.make_reservation( custy.id ) or halt 400
      payment.update( :class_reservation_id => reservation.id )
      Slack.website_purchases("[\##{custy.id}] #{custy.name} (#{custy.email}) donated with a PaymentIntent.")
      { status: 'complete' }.to_json
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
      price = ( data['total_price'].nil? ? 0 : data['total_price'].to_i )/100

      if data['multiplier'] > 1 then
        description = "[\##{custy.id}] #{custy.name} (#{custy.email}) bought #{data['multiplier']} $#{price / data['multiplier'].to_i} tickets for #{eventname}."
      else
        description = "[\##{custy.id}] #{custy.name} (#{custy.email}) bought a $#{price} ticket for #{eventname}."
      end

      charge = StripeMethods::charge_card(data['token']['id'], data['total_price'], data['token']['email'], description, data['metadata']);

      payment = CustomerPayment.create(:customer => custy, :stripe_id => charge.id, :amount => data['total_price'], :reason => description, :type => 'new card', :tag => 'event')
      
      data['multiplier'].to_i.times do 
        EventTicket.create( 
          :customer            => custy, 
          :event_id            => data['event_id'], 
          :included_sessions   => data['included_sessions'], 
          :price               => data['total_price'].to_i / data['multiplier'].to_i,
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
          :price               => params[:total_price].to_i / params[:multiplier].to_i,
          :customer_payment_id => params[:payment_id],
          :pass_transaction_id => params[:pass_transaction_id],
          :event_price_id      => params[:price_id]
        )
      end
      status 204
    end

    def buy_event_privates
      x = request.body.read

      data = JSON.parse x
      p data

      tic = EventTicket.create(
        :customer_id         => data['customer_id'],
        :event_id            => data['event_id'],
        :price               => data['total_price'].to_i,
        :customer_payment_id => data['payment_id']
      )
      
      res = GroupReservation.create(
        :start_time          => data['start_time'],
        :end_time            => data['end_time'],
        :customer_id         => data['customer_id'],
        :payment_id          => data['payment_id'],
        :event_ticket_id     => tic.id,
      )

      data['slots'].each do |slot|
        GroupReservationSlot.create(
          :group_reservation_id => res.id,
          :customer_id          => (slot['customer_id']==0 ? nil : slot['customer_id']),
          :start_time           => data['start_time'],
          :duration_mins        => data['duration_mins'],
        )
      end

      status 204
    end

    def buy_event_passes

      tic = EventTicket.create(
        :customer_id         => params['customer_id'].to_i,
        :event_id            => params['event_id'].to_i,
        :price               => params['total_price'].to_i,
        :customer_payment_id => params['payment_id'].to_i
      )

      params['passes'].each do |index,pass|
        custy = Customer[pass['customer_id'].to_i]
        sess = EventSession[pass['session_id'].to_i]
        EventPass.create( :customer => custy, :ticket => tic, :session => sess )
      end
      
    end

    def group_payment
      group = GroupReservation[params[:reservation_id]] or halt(404, "Couldn't find Reservation")
      payment = CustomerPayment[params[:payment_id]] or halt(404, "Payment Not Found")
      payment.update(:group_reservation => group)
      status 204
    end

    def group_passes
      group = GroupReservation[params[:reservation_id]] or halt(404, "Couldn't find Reservation")
      custy = Customer[params[:customer_id]] or halt(404, "Couldn't find Customer")
      trans = custy.rem_passes( params[:num_passes], group.summary, "" )
      trans.update(:group_reservation => group)
      status 204 
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
