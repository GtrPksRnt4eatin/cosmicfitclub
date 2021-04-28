$SWIPELISTENERS = []

module Sinatra
  module PaymentMethods

    def charge_card
      custy = Customer[params[:customer]]
      params[:email] = custy.email if params[:email].nil?
      params[:metadata] ||= {}
      description = "#{custy.name} purchased #{params[:description]}"  
      charge = StripeMethods::charge_card(params[:token], params[:amount], params[:email], description, params[:metadata])
      CustomerPayment.create(:customer => custy, :stripe_id => charge.id, :amount => params[:amount], :reason => params[:description], :type => 'new card').to_json
    rescue Exception => e
      halt( 400, e.message )
    end

    def charge_saved_card
      custy = Customer[params[:customer]]
      params[:email] = custy.email if params[:email].nil?
      params[:metadata] ||= {}
      description = "#{custy.name} purchased #{params[:description]}"
      charge = StripeMethods::charge_saved(custy.stripe_id, params[:card], params[:amount], description, params[:metadata])
      ( status 402; return charge.message ) if charge.is_a? Stripe::CardError
      CustomerPayment.create(:customer => custy, :stripe_id => charge.id, :amount => params[:amount], :reason => params[:description], :type => 'saved card').to_json
    rescue Exception => e
      halt( 400, e.message )
    end

    def pay_cash
      custy = Customer[params[:customer]]
      CustomerPayment.create(:customer => custy, :stripe_id => nil, :amount => params[:amount], :reason => params[:description], :type => 'cash').to_json
    end

    def card_swipe
      p params
      halt 400 if params[:token].nil?
      $SWIPELISTENERS.each do |out|
        out << "event: swipe\n"
        out << "data: #{params[:token]}\n\n"
      end
    end

    def wait_for_swipe
      content_type 'text/event-stream'
      stream do |out|
        $SWIPELISTENERS << out
        until out.closed?
          sleep(10)
          out << ":keepalive\n\n"
        end
        $SWIPELISTENERS.delete out
      end
      status 200
    end

    def save_card
      custy = Customer[params[:customer_id]] or halt( 404, 'Customer Not Found')
      if custy.stripe_id then
        StripeMethods::add_card( params[:token], custy.stripe_id )
      else
        StripeMethods::create_stripe_customer( custy, params[:token] )
      end
    end

    def set_default_card
      custy = Customer[params[:customer_id]] or halt( 404, 'Customer Not Found')
      custy.stripe_id                        or halt( 404, 'Customer Has No Stripe Account')
      StripeMethods::set_default_card( custy.stripe_id, params[:source_id] ) 
    end

    def remove_card
      custy = Customer[params[:customer_id]] or halt( 404, 'Customer Not Found')
      custy.stripe_id                        or halt( 404, 'Customer Has No Stripe Account')
      StripeMethods::remove_card( custy.stripe_id, params[:source_id] )
    end

  end
end