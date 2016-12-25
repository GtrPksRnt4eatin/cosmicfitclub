require 'stripe'
require_relative 'environment.rb'

Stripe.api_key = ENV['STRIPE_SECRET']

post '/charge' do

  data = JSON.parse request.body.read
  
  if data['type'] == 'plan' then
    customer = Stripe::Customer.create(
      :source   => data['token']['id'],
      :plan     => data['plan_id'],
      :email    => data['token']['email'],
      :metadata => { :name => data['token']['card']['name'] } 
    )
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