require 'stripe'

Stripe.api_key = ENV['STRIPE_SECRET']

class StripeRoutes < Sinatra::Base
	
  post '/webhook' do
    
    event = JSON.parse request.body.read

    case event['type']
    
    when 'customer.created'

      #customer = Customer.find_or_create( :stripe_id => event['data']['object']['id'] ) do |customer|
      #  customer.name  = event['data']['object']['metadata']['name']
      #  customer.email = event['data']['object']['email']
      #  customer.data  = JSON.generate(event['data']['object'])
      #end

      #customer.login = User.create( :reset_token => StripeMethods.generateToken ) if customer.login.nil?
    
    when 'customer.deleted'
      
      customer = Customer.find( :stripe_id => event['data']['object']['id'] )
      customer.destroy unless customer.nil?

    when 'customer.subscription.created'

      customer = Customer.find( :stripe_id => event['data']['object']['customer'] )   
      customer.update( :plan => Plan.find( :stripe_id => event['data']['object']['plan']['id'] ) ) unless customer.nil?

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

  def StripeMethods::create_subscription(plan_id, customer_id)
    Stripe::Subscription.create(
      :plan => plan_id,
      :customer => customer_id
    )['id']
  end

  def StripeMethods::buy_pack(pack_id, customer_id) 
    Stripe::Order.create(
      :currency => 'usd',
      :customer => customer_id,
      :items => [ { :type => 'sku', :parent => pack_id } ]
    ).pay( :customer => customer_id )
  end
  
  def StripeMethods::buy_training(quantity, pack_id, customer_id)
    Stripe::Order.create(
      :currency => 'usd',
      :customer => customer_id,
      :items => [ { :type => 'sku', :parent => pack_id, :quantity => quantity } ]
    ).pay( :customer => customer_id )
  end

  def StripeMethods::charge_customer(customer_id, amount, description, metadata)
    Stripe::Charge.create(
      :amount      => amount,
      :currency    => 'usd',
      :customer    => customer_id,
      :description => description,
      :metadata    => metadata
    )
  end

  def StripeMethods::charge_card(token_id, amount, email, description, metadata)
    charge = Stripe::Charge.create(
      :amount        => amount,
      :currency      => 'usd',
      :source        => token_id,
      :receipt_email => email,
      :description   => description, 
      :metadata      => metadata
    )
  end

  def StripeMethods::find_customer_by_card(token)
    tok = Stripe::Token.retrieve(token['id'])
    ( p "Couldn't find token"; return nil ) if tok.nil?
    Customer.all.each do |custy|
      next if custy.stripe_id.nil?
      stripe_custy = Stripe::Customer.retrieve(custy.stripe_id)
      next if stripe_custy.nil?
      stripe_custy.sources.each do |source|
        return stripe_custy.id if source.fingerprint == tok.card.fingerprint
      end
    end
    return nil
  end

  def StripeMethods::get_customer(customer_id)
    Stripe::Customer.retrieve(customer_id)
  end

  ##########################################################################

  def StripeMethods::sync_plans
    
    p "getting plans from Stripe"
    stripe_plans = Stripe::Plan.list(limit: 100)['data']
    p "#{stripe_plans.count} plans found" 

    stripe_plans.each do |plan|
      next if Plan.find( :stripe_id => plan['id'] )
      puts "Plan #{plan['id']} Not Found...Delete From Stripe (y/n)" 
      resp = gets 
      p plan.delete if resp.chomp=="y"
    end

    Plan.all.each do |plan|
      next unless plan[:stripe_id].nil? || stripe_plans.find_index { |p| p['id'] == plan[:stripe_id] }.nil?
      p plan
      puts "Create on Stripe?(y/n)"
      next unless gets.chomp=="y"

      plan.update( :stripe_id => StripeMethods::generateToken )

      p stripe_plan = Stripe::Plan.create(
        :id       => plan.stripe_id,
        :name     => plan.name,
        :amount   => plan.full_price,
        :interval => plan.term_months == 1 ? "month" : "year", 
        :currency => "usd"
      )

      plan.update( :stripe_id => stripe_plan['id'] )

    end

  end


  def StripeMethods::sync_packages
    
    product = Stripe::Product.create(
      :id => StripeMethods::generateToken,
      :name => "Class Package",
      :attributes => ['name', 'num_passes', 'pass_price'],
      :shippable => false
    )
    
    Package.all.each do |pack|
      next unless pack['stripe_id'].nil?

      sku = Stripe::SKU.create(
        :currency  => 'usd',
        :price     => pack.num_passes * pack.pass_price,
        :inventory => { 'type' => 'infinite' },
        :product   => product['id'],
        :attributes => {
          :name => pack.name,
          :num_passes => pack.num_passes,
          :pass_price => pack.pass_price
        }
      )

      pack.update( :stripe_id => sku['id'] )
    end

  end

  def StripeMethods::sync_training
    
    product = Stripe::Product.create(
      :id => StripeMethods::generateToken,
      :name => "Personal Training",
      :attributes => ['name'],
      :shippable => false
    )

    TrainingPackage.all.each do |pack|
      next unless pack['stripe_id'].nil?

      sku = Stripe::SKU.create(
        :currency => 'usd',
        :price => pack.pass_price,
        :inventory => { 'type' => 'infinite' },
        :product => product['id'],
        :attributes => {
          :name => pack.name
        }
      )

      pack.update( :stripe_id => sku['id'] )
    end

  end

  def StripeMethods::generateToken; @token = rand(36**8).to_s(36) end

end