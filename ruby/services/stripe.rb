require 'stripe'

Stripe.api_key = ENV['STRIPE_SECRET']

class StripeRoutes < Sinatra::Base
	
  post '/charge' do

    p "Charge Posted!"

    data = JSON.parse request.body.read

    customer_id = nil;
    
    client = Client.find( :email => data['token']['email'] )

    if client.nil? then

      p "Client Doesnt Exist, Creating Stripe Customer"

      customer = Stripe::Customer.create(
        :source   => data['token']['id'],
        :email    => data['token']['email'],
        :metadata => { :name => data['token']['card']['name'] } 
      )

      customer_id = customer['id']

    else

      p "Client already has a plan: #{client.plan}" if client.plan != nil

      halt 409 if client.plan != nil  

      customer_id = client.stripe_id

    end

    p "stripe customer id = #{customer_id}, find or create client"

    client = Client.find_or_create( :stripe_id => customer_id ) do |client|
      p "creating client"
      client.name  = data['token']['name']
      client.email = data['token']['email']
    end

    client.user = User.create( :reset_token => StripeMethods.generateToken ) if client.user.nil?

    p "client : #{client}"

    subs = Stripe::Subscription.create(
      :plan => Plan[data['plan_id']].stripe_id,
      :customer => customer_id
    )

    p "Stripe Subscription: #{subs}"

    p "User: #{client.user}"

    status 204
    nil
  end

  post '/webhook' do
    
    event = JSON.parse request.body.read

    case event['type']
    
    when 'customer.created'

      customer = Customer.find_or_create( :stripe_id => event['data']['object']['id'] ) do |customer|
        customer.name  = event['data']['object']['metadata']['name']
        customer.email = event['data']['object']['email']
        customer.data  = JSON.generate(event['data']['object'])
      end

      customer.user = User.create( :reset_token => StripeMethods.generateToken ) if customer.user.nil?
    
    when 'customer.deleted'
      
      customer = Customer.find( :stripe_id => event['data']['object']['id'] )
      customer.destroy unless customer.nil?

    when 'customer.subscription.created'

      customer = Customer.find( :stripe_id => event['data']['object']['customer'] )   
      customer.update( :plan => Plan.find( :stripe_id => event['data']['object']['plan']['id'] ) ) unless customer.nil?

      Mail.send_membership_welcome(client.email, {
        :name => customer.name, 
        :plan_name => customer.plan.name,
        :login_url => customer.user.activated? ? "https://cosmicfitclub.com/login" : "https://cosmicfitclub.com/auth/activate?token=#{customer.user.token}"
      })

    when 'customer.subscription.deleted'
      
      customer = Customer.find( :stripe_id => event['data']['object']['id'] )
      customer.update( :plan => nil )

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