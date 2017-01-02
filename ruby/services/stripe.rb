require 'stripe'

Stripe.api_key = ENV['STRIPE_SECRET']

class StripeRoutes < Sinatra::Base
	
  post '/charge' do

    data = JSON.parse request.body.read

    customer = Stripe::Customer.create(
      :source   => data['token']['id'],
      :plan     => data['plan_id'],
      :email    => data['token']['email'],
      :metadata => { :name => data['token']['card']['name'] } 
    )

    client = Client.find_or_create(:stripe_id => customer.id) do |cust|
      cust.name  = data['token']['card']['name']
      cust.email = data['token']['email']
    end

    if data['type'] == 'plan' then
      
    end







#  charge = Stripe::Charge.create(
#    :amount      => @amount,
#    :description => 'Sinatra Charge',
#    :currency    => 'usd',
#    :customer    => customer.id
#  )

#  slim :charged
  end 

  error Stripe::CardError do
    env['sinatra.error'].message
  end

end   