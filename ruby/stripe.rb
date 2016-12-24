require 'stripe'
require_relative 'environment.rb'

Stripe.api_key = ENV['STRIPE_SECRET']

post '/charge' do

  data = JSON.parse document.body.read
  p data

#  @amount = 500

  customer = Stripe::Customer.create(
    :source  => data['token']['id'],
    :plan    => data['plan_id']
  )

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