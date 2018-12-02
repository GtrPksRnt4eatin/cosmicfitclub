$SWIPELISTENERS = []

module Sinatra
  module CheckoutHelpers

    def buy_plan
      data = JSON.parse request.body.read
      custy = Customer.get_from_token( data['token'] )
      halt 409 if ( custy.plan != nil ) && ( !custy.plan.deactivated ) ## Already Has A Plan, Log in to Update instead
      custy.add_subscription( data['plan_id'] )
      Slack.post("[\##{custy.id}] #{custy.name} (#{custy.email}) became a member!")
      status 204
    end

    def buy_pack
      data = JSON.parse request.body.read
      custy = logged_in? ? customer : Customer.get_from_email( data['token']['email'], data['token']['card']['name'] )
      custy.buy_pack_card( data['pack_id'], data['token'] )
      Slack.post("[\##{ custy.id }] #{ custy.name } (#{ custy.email }) bought a #{ Package[data['pack_id']].name }.")
      status 204
    end

    def buy_pack_precharged
      custy = Customer[params[:customer_id]] or halt 403
      custy.buy_pack_precharged( params[:pack_id], params[:payment_id] )
      Slack.post("[\##{custy.id}] #{custy.name} (#{custy.email}) bought a #{Package[params[:pack_id]].name} precharged.")
    end

    def buy_training
      data = JSON.parse request.body.read
      custy = Customer.get_from_token( data['token'] )
      custy.buy_training( data['num_hours'], 2, data['trainer'] )
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
        :stripe_payment_id => charge['id'],
        :event_price_id => data['selected_price'] ? data['selected_price']['id'] : nil
      )
      selected_price_name = (data['selected_price'] ? data['selected_price']['title'] : "")
      Slack.post("[\##{custy.id}] #{custy.name} (#{custy.email}) bought a $#{data['total_price']/100} #{selected_price_name} ticket for #{eventname}.")
      status 204
    end

    def buy_event_precharged
      EventTicket.create(
        :customer_id       => params[:customer_id],
        :event_id          => params[:event_id],
        :included_sessions => params[:included_sessions],
        :price             => params[:total_price],
        :stripe_payment_id => params[:payment_id],
        :event_price_id    => params[:price_id]
      )
      custy = Customer[params[:customer_id]]
      event = Event[params[:event_id]]
      price = EventPrice[params[:event_price_id]]
      Slack.post("[\##{custy.id}] #{custy.name} (#{custy.email}) bought a $#{params[:total_price].to_f/100} #{price.title} ticket for #{event.name}.")
      status 204
    end

    def register_event
      data = JSON.parse request.body.read
      custy = logged_in? ? customer : Customer.find( :email => data['email'] );
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
