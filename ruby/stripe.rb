require 'stripe'
require_relative 'environment.rb'

Stripe.api_key = ENV['STRIPE_SECRET']

post '/charge' do

  @amount = 500

  customer = Stripe::Customer.create(
    :email => 'customer@example.com',
    :source  => params[:stripeToken]
  )

  charge = Stripe::Charge.create(
    :amount      => @amount,
    :description => 'Sinatra Charge',
    :currency    => 'usd',
    :customer    => customer.id
  )

  slim :charged
end

error Stripe::CardError do
  env['sinatra.error'].message
end