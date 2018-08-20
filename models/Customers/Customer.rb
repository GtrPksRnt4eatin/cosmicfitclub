
class Customer < Sequel::Model
  
  one_through_one :plan, :join_table => :subscriptions
  one_to_many :subscriptions
  one_to_one :login, :class=>:User
  one_to_many :passes
  one_to_many :tickets, :class=>:EventTicket
  one_to_many :event_checkins, :class=> :EventCheckin
  one_to_many :training_passes
  one_to_one  :waiver
  one_to_many :nfc_tags
  many_to_one :wallet
  one_to_many :reservations, :class=>:ClassReservation
  one_to_many :comp_tickets
  one_to_many :payments, :class=>:CustomerPayment
  many_to_many :children, :class => :Customer, :join_table => :parents_children, :left_key => :parent_id, :right_key => :child_id
  many_to_many :parents,  :class => :Customer, :join_table => :parents_children, :left_key => :child_id,  :right_key => :parent_id
  one_to_many  :staff

########################### Instance Methods ###########################

  def Customer.is_new? (email)
    customer = Customer[ :email => email.downcase ]
    customer.nil?
  end

  def Customer.get_from_token(token)
    customer = find_or_create( :email => token['email'] ) do |cust| 
      cust.name = token['card']['name']
      cust.add_passes(1,"First Class Free", "")
    end
    customer.update( :stripe_id => StripeMethods::create_customer(token) ) if customer.stripe_id.nil?
    customer.create_login if customer.login.nil? 
    return customer
  end

  def Customer.get_from_email(email, name)
    customer = find_or_create( :email => email.downcase ) do |cust| 
      cust.name = name
      cust.add_passes(1,"First Class Free", "")
    end    
    customer.create_login if customer.login.nil? 
    return customer
  end

  def Customer.find_by_email(email)
    Customer[ :email => email.downcase ]
  end

########################### Instance Methods ###########################

############################ Account/Login #############################

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
    login_url    = "https://cosmicfitclub.com/auth/login"
    activate_url = "https://cosmicfitclub.com/auth/activate?token=#{login.reset_token}"
    Mail.account_created(email, { :name => name, :url => login.activated? ? login_url : activate_url })
  end

  def payment_sources
    return [] if stripe_id.nil?
    StripeMethods.get_customer(stripe_id)['sources']['data']
  end

  def add_child(child)
    ( self.wallet = Wallet.create; self.save ) if self.wallet.nil?
    child.update( :wallet => self.wallet )
    super
  end

  def merge_with( customer_id )

    other = Customer[customer_id] or return false

    if !self.wallet.nil? then
      other.update( :wallet => Wallet.create ) if other.wallet.nil?
      self.wallet.transactions.each { |trans| trans.update( :wallet_id => other.wallet.id ) }
      other.wallet.pass_balance = other.wallet.pass_balance + self.wallet.pass_balance
    end

    self.reservations.each   { |res| res.customer = other; res.save }
    self.payments.each       { |pay| pay.customer = other; pay.save }
    self.tickets.each        { |tic| tic.customer = other; tic.save }
    self.event_checkins.each { |chk| chk.customer = other; chk.save }

  end

  def delete
    (puts "Customer Not Empty"; return) unless self.can_delete?
    super
  end

  def can_delete?
    (puts 'subscriptions';  return false) if self.subscriptions.count > 0
    (puts 'passes';         return false) if self.passes.count > 0
    (puts 'tickets';        return false) if self.tickets.count > 0
    (puts 'train_passes';   return false) if self.training_passes.count > 0
    (puts 'wallet';         return false) if self.wallet != nil
    (puts 'reservations';   return false) if self.reservations.count > 0
    (puts 'tickets';        return false) if self.comp_tickets.count > 0
    (puts 'payments';       return false) if self.payments.count > 0
    (puts 'event_checkins'; return false) if self.event_checkins.count > 0
    return true
  end

  def email_login_url
    login_url       = "https://cosmicfitclub.com/auth/login"
    activation_url  = "https://cosmicfitclub.com/auth/activate?token=#{login.reset_token}"
    login.activated? ? login_url : activation_url 
  end

############################ Account/Login #############################

########################### Attribute Access ###########################

  def email
    val = super
    val.nil? ? '' : val.downcase
  end

  def before_save
    self.email = self.email.downcase
    super
  end

########################### Attribute Access ###########################

############################ Subscriptions #############################

  def subscription
    self.subscriptions.find { |x| !x.deactivated }
  end

  def membership_plan
    return Plan[0] if self.subscription.nil?
    self.subscription.plan
  end

  def membership_plan
    return { :id => 0, :name => "None" } if self.subscription.nil?
    return { :id => 0, :name => "None" } if self.subscription.deactivated
    { :id => subscription.plan.id, :name => subscription.plan.name }
  end

  def add_subscription(plan_id)
    plan = Plan[plan_id]
    StripeMethods::create_subscription( plan.stripe_id, stripe_id )
    self.update( :plan => plan )

    model = {
      :name => name, 
      :plan_name => plan.name,
      :login_url => email_login_url
    }

    Mail.membership_welcome(email, model) unless login.activated?
    Mail.membership(email, model) if login.activated?
  end

  def use_membership(reason, &block)
    return false if self.subscription.nil?
    MembershipUse.create( :reason=> reason, :membership=>self.subscription ) do |use|
      use.reservation = block.call
    end
  end

  def membership_uses
    return [] if self.subscription.nil?
    self.subscription.uses
  end

############################ Subscriptions #############################

############################ Class Passes ##############################

  def num_passes;    wallet.nil? ? 0 : wallet.pass_balance end

  def pass_transactions
    return [] if self.wallet.nil?
    self.wallet.transactions
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

  def upcoming_reservations
    reservations.select { |res| res.occurrence.nil? ? false : res.occurrence.starttime > Time.now }
  end

  def buy_pack_card(pack_id, token)
    pack = Package[pack_id] or halt 403, "Can't find Pack"
    charge = StripeMethods::charge_card( token['id'], pack.price, email, pack.name, { :pack_id => pack_id } )
    self.add_payment( :stripe_id => charge.id, :amount => charge.amount , :reason =>"Bought #{pack.name}" , :type => 'new card' )
    self.add_passes( pack.num_passes, "Bought #{pack.name}", "" )
    self.send_pack_email(pack)
  end

  def buy_pack_precharged(pack_id, payment_id)
    pack = Package[pack_id] or halt 403, "Can't find Pack"
    payment = CustomerPayment[payment_id] or halt 403, "Can't find Payment"
    payment.customer_id == self.id or halt 403, "Payment doesn't match Customer"
    payment.amount == pack.price or halt 403, "Payment doesn't match amount"
    self.add_passes( pack.num_passes, "Bought #{pack.name}", "" ) 
    self.send_pack_email(pack)
  end

  def send_pack_email(pack)
    model = {
      :name => name,
      :pack_name => pack.name,
      :login_url => email_login_url
    }

    Mail.package_welcome(email, model) unless login.activated?
    Mail.package(email, model) if login.activated?
  end

  def transfer_passes_to(customer_id, number)
    customer = Customer[customer_id]
    return false if customer.nil?
    self.rem_passes(number, "Transferred to #{customer.name} \##{customer.id}", "") or return false
    customer.add_passes(number, "Transferred from #{self.name} \##{self.id}", "") or return false
    return true
  end

############################ Class Passes ##############################

######################### Personal Training ############################

  def num_trainings; training_passes.count end

  def trainings_by_instructor
    training_passes.group_by(&:trainer).map { |k,v| [k,v.count] }.to_h
  end

  def buy_training(quantity, pack_id, trainer)
    pack = TrainingPackage[pack_id]
    StripeMethods::buy_training( quantity, pack.stripe_id, stripe_id )
    quantity.times { self.add_training_pass( TrainingPass.create( :trainer => trainer ) ) }

    model = {
      :name => name,
      :instructor => trainer,
      :quantity => quantity,
      :login_url => email_login_url
    }

    Mail.training_welcome(email, model) unless login.activated?
    Mail.training(email, model) if login.activated?
  end

######################### Personal Training ############################

########################### Event Tickets ##############################

  def upcoming_events
    tickets.select { |tic| tic.event.nil? ? false : tic.event.starttime > Time.now }
  end

########################### Event Tickets ##############################

end
