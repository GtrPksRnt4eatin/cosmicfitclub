require 'stripe'

Stripe.api_key = ENV['STRIPE_SECRET']

class StripeRoutes < Sinatra::Base
	
  post '/charge' do

    data = JSON.parse request.body.read

    customer_id = nil;
    
    client = Client.find( :email => data['token']['email'] )

    if client.nil? then

      customer = Stripe::Customer.create(
        :source   => data['token']['id'],
        :email    => data['token']['email'],
        :metadata => { :name => data['token']['card']['name'] } 
      )

      customer_id = customer['id']

    else

      halt 409 if client.plan != nil  

      customer_id = client.stripe_id

    end

    subs = Stripe::Subscription.create(
      :plan => Plan[data['plan_id']].stripe_id,
      :customer => customer_id
    )

    status 204
    nil
  end

  post '/webhook' do
    event = JSON.parse request.body.read

    case event['type']
    
    when 'customer.created'

      Client.find_or_create( :stripe_id => event['data']['object']['id'] ) do |client|
        client.name  = event['data']['object']['metadata']['name']
        client.email = event['data']['object']['email']
      end
    
    when 'customer.deleted'
      
      client = Client.find( :stripe_id => event['data']['object']['id'] )

      client.destroy unless client.nil?

    when 'customer.subscription.created'

      client = Client.find( :stripe_id => event['data']['object']['customer'] )
    
      client.update( :plan => Plan.find( :stripe_id => event['data']['object']['plan']['id'] ) ) unless client.nil?

    when 'customer.subscription.deleted'
      
      client = Client.find( :stripe_id => event['data']['object']['id'] )

      client.update( :plan => nil )

    end

  end

  error Stripe::CardError do
    env['sinatra.error'].message
  end

end 

module StripeMethods

  def StripeMethods::sync_plans

    stripe_plans = Stripe::Plan.list['data']

    stripe_plans.each do |plan|
      plan.delete unless Plan.find( :stripe_id => plan['id'] )
    end

    Plan.all.each do |plan|
      next unless plan['stripe_id'].nil? || stripe_plans.find_index { |p| p['id'] == plan['stripe_id'] }.nil?
      plan.update(:stripe_id => StripeMethods::generateToken)

      Stripe::Plan.create(
        :id       => plan.stripe_id,
        :name     => plan.name,
        :amount   => plan.full_price,
        :interval => plan.term_months == 1 ? "month" : "year", 
        :currency => "usd"
      )
    end

  end

  def StripeMethods::generateToken; @token = rand(36**8).to_s(36) end

end