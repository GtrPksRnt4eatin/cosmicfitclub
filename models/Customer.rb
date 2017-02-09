class Customer < Sequel::Model
  
  one_through_one :plan, :join_table => :subscriptions
  one_to_one :subscription
  one_to_one :login, :class=>:User
  one_to_many :passes
  one_to_many :training_passes
  one_to_one :waiver

  def Customer.is_new? (email)
    customer = Customer[ :email => email ]
    customer.nil?
  end

  def Customer.get_from_token(token)
    customer = find_or_create( :email => token['email'] ) { |cust| cust.name = token['card']['name'] }
    customer.update( :stripe_id => StripeMethods::create_customer(token) ) if customer.stripe_id.nil?
    customer.create_login if customer.login.nil? 
    return customer
  end

  def create_login
    return unless login.nil?
    User.create( :customer => self )
  end

  def send_new_account_email
    Mail.account_created(email, {
      :name => name,
      :url => login.activated? ? "https://cosmicfitclub.com/auth/login" : "https://cosmicfitclub.com/auth/activate?token=#{login.reset_token}"
    })
  end

  def add_subscription(plan_id)
    plan = Plan[plan_id]
    StripeMethods::create_subscription( plan.stripe_id, stripe_id )
    self.update( :plan => plan )

    Mail.membership_welcome(email, {
      :name => name, 
      :plan_name => plan.name,
      :login_url => login.activated? ? "https://cosmicfitclub.com/auth/login" : "https://cosmicfitclub.com/auth/activate?token=#{login.reset_token}"
    })
  end

  def buy_pack(pack_id, token)
    pack = Package[pack_id]
    StripeMethods::buy_pack( pack.stripe_id, stripe_id, token )
    pack.num_passes.times { self.add_pass( Pass.create() ) }

    Mail.package_welcome(email, {
      :name => name,
      :pack_name => pack.name,
      :login_url => login.activated? ? "https://cosmicfitclub.com/auth/login" : "https://cosmicfitclub.com/auth/activate?token=#{login.reset_token}"
    })
  end

  def buy_training(quantity, pack_id, token, trainer)
    pack = TrainingPackage[pack_id]
    StripeMethods::buy_training( quantity, pack.stripe_id, stripe_id, token )
    quantity.times { self.add_training_pass( TrainingPass.create( :trainer => trainer ) ) }

    Mail.training_welcome(email, {
      :name => name,
      :login_url => login.activated? ? "https://cosmicfitclub.com/auth/login" : "https://cosmicfitclub.com/auth/activate?token=#{login.reset_token}"
    })
  end

  def payment_sources
    return [] if stripe_id.nil?
    StripeMethods.get_customer(stripe_id)['sources']['data']
  end

  def num_passes
    passes.count
  end

  def num_trainings
    training_passes.count
  end

end