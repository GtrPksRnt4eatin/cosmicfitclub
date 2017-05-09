class Customer < Sequel::Model

  plugin :json_serializer
  
  one_through_one :plan, :join_table => :subscriptions
  one_to_one :subscription
  one_to_one :login, :class=>:User
  one_to_many :passes
  one_to_many :tickets, :class=>:EventTicket
  one_to_many :training_passes
  one_to_one :waiver
  one_to_many :nfc_tags

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

  def payment_sources
    return [] if stripe_id.nil?
    StripeMethods.get_customer(stripe_id)['sources']['data']
  end

  def upcoming_events
    tickets.select { |tic| tic.event.starttime > Time.now }
  end

  def num_passes;    passes.count          end
  def num_trainings; training_passes.count end

  def trainings_by_instructor
    training_passes.group_by(&:trainer).map { |k,v| [k,v.count] }.to_h
  end

  def create_login
    return unless login.nil?
    User.create( :customer => self )
  end

  def send_new_account_email
    create_login
    Mail.account_created(email, {
      :name => name,
      :url => login.activated? ? "https://cosmicfitclub.com/auth/login" : "https://cosmicfitclub.com/auth/activate?token=#{login.reset_token}"
    })
  end

  def add_subscription(plan_id)
    plan = Plan[plan_id]
    StripeMethods::create_subscription( plan.stripe_id, stripe_id )
    self.update( :plan => plan )

    model = {
      :name => name, 
      :plan_name => plan.name,
      :login_url => login.activated? ? "https://cosmicfitclub.com/auth/login" : "https://cosmicfitclub.com/auth/activate?token=#{login.reset_token}"
    }

    Mail.membership_welcome(email, model) unless login.activated?
    Mail.membership(email, model) if login.activated?
  end

  def buy_pack(pack_id)
    pack = Package[pack_id]
    StripeMethods::buy_pack( pack.stripe_id, stripe_id )
    pack.num_passes.times { self.add_pass( Pass.create() ) }

    model = {
      :name => name,
      :pack_name => pack.name,
      :login_url => login.activated? ? "https://cosmicfitclub.com/auth/login" : "https://cosmicfitclub.com/auth/activate?token=#{login.reset_token}"
    }

    Mail.package_welcome(email, model) unless login.activated?
    Mail.package(email, model) if login.activated?
  end

  def buy_pack_card(pack_id, token)
    pack = Package[pack_id]
    StripeMethods::charge_card( stripe_id, token, pack.price, pack.name, { :pack_id => pack.id } )
    pack.num_passes.times { self.add_pass( Pass.create() ) }

    model = {
      :name => name,
      :pack_name => pack.name,
      :login_url => login.activated? ? "https://cosmicfitclub.com/auth/login" : "https://cosmicfitclub.com/auth/activate?token=#{login.reset_token}"
    }

    Mail.package_welcome(email, model) unless login.activated?
    Mail.package(email, model) if login.activated?
  end

  def buy_training(quantity, pack_id, trainer)
    pack = TrainingPackage[pack_id]
    StripeMethods::buy_training( quantity, pack.stripe_id, stripe_id )
    quantity.times { self.add_training_pass( TrainingPass.create( :trainer => trainer ) ) }

    model = {
      :name => name,
      :instructor => trainer,
      :quantity => quantity,
      :login_url => login.activated? ? "https://cosmicfitclub.com/auth/login" : "https://cosmicfitclub.com/auth/activate?token=#{login.reset_token}"
    }

    Mail.training_welcome(email, model) unless login.activated?
    Mail.training(email, model) if login.activated?
  end

end

################################################################ ROUTES ###########################################################################

class CustomerRoutes < Sinatra::Base

  get '/' do
    Customer.all.to_json
  end

  get '/:id/payment_sources' do
    custy = Customer[params[:id]]
    halt 404 if custy.nil?
    JSON.generate custy.payment_sources
  end

  get '/:id/class_passes' do
    custy = Customer[params[:id]]
    halt 404 if custy.nil?
    custy.passes.to_json
  end

  get '/:id/status' do
    custy = Customer[params[:id]]
    halt 404 if custy.nil?
    return '{ "plan": { "name": "None" }}' if custy.subscription.nil? 
    custy.subscription.to_json(:include => [ :plan ] )
  end

end