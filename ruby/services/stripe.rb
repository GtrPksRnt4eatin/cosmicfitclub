require 'stripe'

Stripe.api_key = ENV['STRIPE_SECRET']

class StripeRoutes < Sinatra::Base
	
  post '/charge' do

    data = JSON.parse request.body.read

    client = Client.find_or_create(:email => data['token']['email']) do |cust|
      cust.name  = data['token']['card']['name']
      customer = Stripe::Customer.create(
        :source   => data['token']['id'],
        :email    => data['token']['email'],
        :metadata => { :name => data['token']['card']['name'] } 
      )
      cust.stripe_id = customer.id
    end
    
    subs = Stripe::Subscription.create(
      :plan => data['plan_id'].to_s,
      :customer => client.stripe_id
    )

    client.update(:plan => data['plan_id'])

  end

  post '/webhook' do
    data = JSON.parse request.body.read
    p data
  end

  error Stripe::CardError do
    env['sinatra.error'].message
  end

  def find_client_by_email(email)

  end

  def find_client_by_card(token)
    token = Stripe::Token.retrieve(token['id'])
  end



end   