require 'stripe'

Stripe.api_key = ENV['STRIPE_SECRET']

class StripeRoutes < Sinatra::Base
	
  post '/webhook' do
    
    event = JSON.parse request.body.read

    case event['type']

    when 'customer.subscription.created'

      customer = Customer.find( :stripe_id => event['data']['object']['customer'] )
      #subscription = Subscription.find( :stripe_id => )
      #customer.update( :plan => Plan.find( :stripe_id => event['data']['object']['plan']['id'] ) ) unless customer.nil?
      Slack.post("#{customer.to_list_string} Subscription Created!")

    when 'customer.subscription.deleted'
      
      customer = Customer.find( :stripe_id => event['data']['object']['customer'] )
      subscription = Subscription.find( :stripe_id => event['data']['object']['id'] )
      subscription.cancel unless subscription.nil?
      Slack.post("#{customer.try(:to_list_string)} Subscription Deleted!")

    when 'customer.subscription.trial_will_end'

      customer = Customer.find( :stripe_id => event['data']['object']['customer'] ) 
      Slack.post("#{customer.to_list_string} Trial Ending on #{Time.at(event['data']['object']['trial_end']).to_s}")

    when 'invoice.upcoming'

      customer = Customer.find( :stripe_id => event['data']['object']['customer'] ) 
      Slack.post("#{customer.to_list_string} #{event['data']['object']['total']} Payment Due On #{Time.at(event['data']['object']['trial_end']).to_s}")

    else

      Slack.post("Stripe Webhook: #{ event['type'] }")

    end

  end

  error Stripe::CardError do
    env['sinatra.error'].message
  end

end 

module StripeMethods

  def StripeMethods::refund(charge_id)
    Stripe::Refund.create( :charge => charge_id )
  rescue Stripe::InvalidRequestError => e
    p e.message
  end

  def StripeMethods::create_stripe_customer(customer, card_token)
    id = Stripe::Customer.create(
      :source   => token['id'],
      :name     => customer.name,
      :email    => customer.email
    )['id']
    customer.update( :stripe_id => id )
  rescue Exception => e
    Slack.err("Stripe Error", e)
  end

  def StripeMethods::add_card(token_id, customer_id)
    Stripe::Customer.create_source( customer_id, { source: token_id } )
  rescue Exception => e
    Slack.err("Stripe Error", e)
  end

  def StripeMethods::set_default_card(customer_id, source_id)
    Stripe::Customer.update( customer_id, { default_source: source_id } )
  rescue Exception => e
    Slack.err("Stripe Error", e)
  end

  def StripeMethods::remove_card(customer_id, source_id)
    Stripe::Customer.delete_source( customer_id, source_id )
  rescue Exception => e
    Slack.err("Stripe Error", e)
  end

  def StripeMethods::create_customer(token)
    Stripe::Customer.create(
      :source   => token['id'],
      :email    => token['email'],
      :metadata => { :name => token['card']['name'] } 
    )['id']
  end

  def StripeMethods::create_subscription(plan_id, customer_id)
    Stripe::Subscription.create(
      :plan => plan_id,
      :customer => customer_id
    )['id']
  end

  def StripeMethods::buy_pack(pack_id, customer_id) 
    Stripe::Order.create(
      :currency => 'usd',
      :customer => customer_id,
      :items => [ { :type => 'sku', :parent => pack_id } ]
    ).pay( :customer => customer_id )
  end
  
  def StripeMethods::buy_training(quantity, pack_id, customer_id)
    Stripe::Order.create(
      :currency => 'usd',
      :customer => customer_id,
      :items => [ { :type => 'sku', :parent => pack_id, :quantity => quantity } ]
    ).pay( :customer => customer_id )
  end

  def StripeMethods::charge_customer(customer_id, amount, description, metadata)
    Stripe::Charge.create(
      :amount      => amount,
      :currency    => 'usd',
      :customer    => customer_id,
      :description => description,
      :metadata    => metadata
    )
  end

  def StripeMethods::charge_card(token_id, amount, email, description, metadata)
    Stripe::Charge.create(
      :amount        => amount,
      :currency      => 'usd',
      :source        => token_id,
      :receipt_email => email,
      :description   => description, 
      :metadata      => metadata
    )
  end

  def StripeMethods::charge_saved(customer_id, card_id, amount, description, metadata)
    Stripe::Charge.create(
      :amount      => amount,
      :currency    => 'usd',  
      :customer    => customer_id,
      :card        => card_id,
      :description => description,
      :metadata    => metadata
    )
  end

  def StripeMethods::find_customer_by_card(token)
    tok = Stripe::Token.retrieve(token['id'])
    ( p "Couldn't find token"; return nil ) if tok.nil?
    Customer.all.each do |custy|
      next if custy.stripe_id.nil?
      stripe_custy = Stripe::Customer.retrieve(custy.stripe_id)
      next if stripe_custy.nil?
      stripe_custy.sources.each do |source|
        return stripe_custy.id if source.fingerprint == tok.card.fingerprint
      end
    end
    return nil
  end

  def StripeMethods::get_customer(customer_id)
    Stripe::Customer.retrieve(customer_id)
  end

  def StripeMethods::get_subscription(subscription_id)
    Stripe::Subscription.retrieve(subscription_id)
  end

  def StripeMethods::get_payment_totals(payment_id)
    empty_row = { :gross => 0, :fees => 0, :refunds => 0, :net => 0 }

    return empty_row unless payment_id
     
    charge  = Stripe::Charge.retrieve             payment_id                 rescue nil
    trans   = Stripe::BalanceTransaction.retrieve charge.balance_transaction rescue nil

    return empty_row if trans.nil?

    refunds = charge.refunds.data.map do |refund|
      Stripe::BalanceTransaction.retrieve refund.balance_transaction rescue nil
    end.map(&:net).reduce(0,:+)

    return { :gross => trans.try(:amount), :fees =>  trans.try(:fee), :refunds => refunds, :net => refunds + trans.try(:net),   }
  end

  ##########################################################################

  def StripeMethods::generateToken; @token = rand(36**8).to_s(36) end

end