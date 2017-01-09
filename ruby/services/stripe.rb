require 'stripe'

Stripe.api_key = ENV['STRIPE_SECRET']

class StripeRoutes < Sinatra::Base
	
  post '/webhook' do
    
    event = JSON.parse request.body.read

    case event['type']
    
    when 'customer.created'

      customer = Customer.find_or_create( :stripe_id => event['data']['object']['id'] ) do |customer|
        customer.name  = event['data']['object']['metadata']['name']
        customer.email = event['data']['object']['email']
        customer.data  = JSON.generate(event['data']['object'])
      end

      customer.login = User.create( :reset_token => StripeMethods.generateToken ) if customer.login.nil?
    
    when 'customer.deleted'
      
      customer = Customer.find( :stripe_id => event['data']['object']['id'] )
      customer.destroy unless customer.nil?

    when 'customer.subscription.created'

      customer = Customer.find( :stripe_id => event['data']['object']['customer'] )   
      customer.update( :plan => Plan.find( :stripe_id => event['data']['object']['plan']['id'] ) ) unless customer.nil?

      Mail.send_membership_welcome(customer.email, {
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

  def StripeMethods::create_customer(token)
    Stripe::Customer.create(
      :source   => token['id'],
      :email    => token['email'],
      :metadata => { :name => token['card']['name'] } 
    )['id']
  end

  def StripeMethods::create_subscription(plan_id,customer_id)
    Stripe::Subscription.create(
      :plan => plan_id,
      :customer => customer_id
    )['id']
  end

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