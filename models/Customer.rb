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
  many_to_one :wallet
  one_to_many :reservations, :class=>:ClassReservation

  def Customer.is_new? (email)
    customer = Customer[ :email => email.downcase ]
    customer.nil?
  end

  def Customer.get_from_token(token)
    customer = find_or_create( :email => token['email'] ) { |cust| cust.name = token['card']['name'] }
    customer.update( :stripe_id => StripeMethods::create_customer(token) ) if customer.stripe_id.nil?
    customer.create_login if customer.login.nil? 
    return customer
  end

  def Customer.get_from_email(email, name)
    customer = find_or_create( :email => email.downcase ) { |cust| cust.name = name }
    customer.create_login if customer.login.nil? 
    return customer
  end

  def Customer.find_by_email(email)
    Customer[ :email => email.downcase ]
  end

  def email
    super.downcase
  end

  def before_save
    self.email = self.email.downcase
    super
  end

  def payment_sources
    return [] if stripe_id.nil?
    StripeMethods.get_customer(stripe_id)['sources']['data']
  end

  def upcoming_events
    tickets.select { |tic| tic.event.nil? ? false : tic.event.starttime > Time.now }
  end

  def num_passes;    wallet.nil? ? 0 : wallet.pass_balance end
  def num_trainings; training_passes.count end

  def trainings_by_instructor
    training_passes.group_by(&:trainer).map { |k,v| [k,v.count] }.to_h
  end

  def create_login
    return unless login.nil?
    User.create( :customer => self )
  end

  def reset_password
    create_login
    login.reset_password
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

  def buy_pack(pack_id, token)
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
    StripeMethods::charge_card( token['id'], pack.price, email, pack.name, { :pack_id => pack_id } )
    #pack.num_passes.times { self.add_pass( Pass.create() ) }
    self.add_passes( pack.num_passes, "Bought #{pack.name}", "" )

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

  def add_passes( number, reason, notes )
    ( self.wallet = Wallet.create; self.save ) if self.wallet.nil?
    self.wallet.add_passes( number, reason, notes )
  end

  def rem_passes( number, reason, notes )
    return false if self.wallet.nil?
    return self.wallet.rem_passes( number, reason, notes )
  end

  def use_class_pass(reason, &block)
    self.wallet.use_pass(reason, &block)
  end

  def use_membership(reason, &block)
    return false if self.subscription.nil?
    MembershipUse.create( :reason=> reason, :membership=>self.subscription ) do |use|
      use.reservation = block.call
    end
  end

  def pass_transactions
    return [] if self.wallet.nil?
    self.wallet.transactions
  end

  def transfer_passes_to(customer_id, number)
    customer = Customer[customer_id]
    return false if customer.nil?
    self.rem_passes(number, "Transferred to #{customer.name} \##{customer.id}", "") or return false
    customer.add_passes(number, "Transferred from #{self.name} \##{self.id}") or return false
    return true
  end

  def membership_uses
    return [] if self.subscription.nil?
    self.subscription.uses
  end

end

class CustomerPayment < Sequel::Model
  
  many_to_one :customer
  many_to_one :reservation, :class => :ClassReservation, :key => :class_reservation_id

  def undo
    StripeMethods::refund(self.stripe_id) if self.stripe_id
    self.delete
  end

end

################################################################ ROUTES ###########################################################################

class CustomerRoutes < Sinatra::Base

  get '/' do
    Customer.all.to_json
  end

  get '/:id' do
    Customer[params[:id]].to_json(:include=>:payment_sources)
  end

  get '/:id/payment_sources' do
    custy = Customer[params[:id]]
    halt 404 if custy.nil?
    JSON.generate custy.payment_sources
  end

  get '/:id/class_passes' do
    custy = Customer[params[:id]]
    halt 404 if custy.nil?
    custy.num_passes.to_json
  end

  get '/:id/status' do
    custy = Customer[params[:id]]
    halt 404 if custy.nil?
    return '{ "plan": { "name": "None" }}' if custy.subscription.nil? 
    custy.subscription.to_json(:include => [ :plan ] )
  end

  get '/:id/reservations' do
    custy = Customer[params[:id]]
    halt 404 if custy.nil?
    JSON.generate custy.reservations.map { |res| { :id => res.id, :classname => res.occurrence.classdef.name, :instructor=> res.occurrence.teacher.name, :starttime => res.occurrence.starttime } }
  end

  get '/:id/transaction_history' do
    custy = Customer[params[:id]]
    halt 404 if custy.nil?
    data = {
      :pass_transactions => custy.pass_transactions,
      :membership_uses => custy.membership_uses 
    }
    data.to_json
  end

end