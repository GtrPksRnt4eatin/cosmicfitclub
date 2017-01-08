require 'sinatra/base'

class Checkout < Sinatra::Base
  
  enable :sessions	
  set :root, File.dirname(__FILE__)

  register Sinatra::PageFolders
  register Sinatra::SharedResources
  helpers  Sinatra::ViewHelpers

  get('/plan/:id') { render_page :plan     }
  get('/pack/:id') { render_page :pack     }
  get('/complete') { render_page :complete }

  post('/charge')  { CheckoutHelpers.buy_plan }

end


module CheckoutHelpers

  def CheckoutHelpers.create_customer(token_id, email, name) 
  	p "Creating Stripe Customer"

    customer = Stripe::Customer.create(
      :source   => data['token']['id'],
      :email    => data['token']['email'],
      :metadata => { :name => data['token']['card']['name'] } 
    )

    customer['id']
  end



  def CheckoutHelpers.buy_plan

    data = JSON.parse request.body.read

    p data

    customer_id = nil;
    
    client = Client.find( :email => data['token']['email'] )

    if client.nil? then
      customer_id = create_customer(data['token']['id'], data['token']['email'], data['token']['card']['name'])
    else
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

end