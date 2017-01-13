class Customer < Sequel::Model
  
  one_through_one :plan, :join_table => :subscriptions
  one_to_one :subscription
  one_to_many :login, :class=>:User
  one_to_many :passes

  def Customer.get_from_token(token)
    customer = find_or_create( :email => token['email'] ) { |cust| cust.name = token['card']['name'] }
    customer.update( :stripe_id => StripeMethods::create_customer(token) ) if customer.stripe_id.nil?
    customer.update( :login => User.create ) if customer.login.nil? 
    return customer
  end

  def add_subscription(plan_id)
    plan = Plan[plan_id]
    StripeMethods::create_subscription(plan.stripe_id, stripe_id)
    self.update( :plan => plan )    
  end

  def buy_pack(pack_id)
    pack = Package[pack_id]
    StripeMethods::buy_pack( pack.stripe_id, stripe_id )
    pack.num_passes.times { self.add_pass( Pass.create() ) }
  end

  def payment_sources
    #StripeMethods.get_customer(stripe_id)['sources']['data']
  end

  def num_passes
    passes.count
  end

end