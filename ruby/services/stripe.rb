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

      customer_id = client['stripe_id']

    end

    subs = Stripe::Subscription.create(
      :plan => data['plan_id'].to_s,
      :customer => client.stripe_id
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
    
    when 'customer.subscription.created'

      client = Client.find( :stripe_id => event['data']['object'] )
    
      client.update( :plan => Plan[event['data']['object']['plan']['id']] ) unless client.nil?

    end
    
  end

  error Stripe::CardError do
    env['sinatra.error'].message
  end

  def create_new_membership(token)

  end

end   