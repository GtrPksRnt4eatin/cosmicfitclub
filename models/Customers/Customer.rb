
class Customer < Sequel::Model
  
  one_to_one      :staff
  one_to_one      :login, :class=>:User
  one_through_one :plan, :join_table => :subscriptions

  one_to_many  :subscriptions
  one_to_many  :passes
  one_to_many  :tickets, :class=>:EventTicket
  one_to_many  :event_checkins, :class=> :EventCheckin
  one_to_many  :training_passes
  one_to_many  :waivers
  one_to_many  :nfc_tags
  one_to_many  :reservations, :class=>:ClassReservation
  one_to_many  :comp_tickets
  one_to_many  :payments, :class=>:CustomerPayment
  one_to_many  :hourly_punches
  one_to_many  :event_passes
  one_to_many  :gift_certificates
  one_to_many  :covid_questionaires
  one_to_many  :group_reservations
  one_to_many  :group_reservation_slots

  many_to_one :wallet
  many_to_many :children, :class => :Customer, :join_table => :parents_children, :left_key => :parent_id, :right_key => :child_id
  many_to_many :parents,  :class => :Customer, :join_table => :parents_children, :left_key => :child_id,  :right_key => :parent_id
  
  many_to_many :collaborating_events, :class=>:Event, :join_table=>:event_collaborators, :left_key=>:customer_id, :right_key=>:event_id

############################ Class Methods ###########################

  def Customer::list
    Customer.all.map(&:to_list_hash) 
  end
  
  def Customer::exists? (email) 
    !! Customer[ :email => email.downcase ]
  end
 
  def Customer.is_new? (email)
    ! Customer[ :email => email.downcase ]
  end

  def Customer.get_from_token(token)
    custy = find_or_create( :email => token['email'].downcase ) { |cust| cust.name = token['card']['name'] }
    custy.update( :stripe_id => StripeMethods::create_customer(token) ) if custy.stripe_id.nil?
    return custy
  end

  def Customer.get_from_email(email, name)
    find_or_create( :email => email.downcase.strip ) { |cust| cust.name = name }    
  end

  def Customer.find_by_email(email)
    Customer[ :email => email.downcase.strip ]
  end

############################ Class Methods ###########################

############################ Account/Login #############################

  def create_login
    User.create( :customer => self ) if self.login.nil?
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

  def share_wallet_with(partner)
    ( self.wallet = Wallet.create; self.save ) if self.wallet.nil?
    self.wallet << partner.wallet unless partner.wallet.nil?
    partner.update( :wallet=>self.wallet )
  end

  def add_child(child)
    self.share_wallet_with(child)
    super
  end

  def merge_with( customer_id )

    other = Customer[customer_id] or return false

    self.reservations.each      { |res| res.customer = other; res.save }
    self.payments.each          { |pay| pay.customer = other; pay.save }
    self.tickets.each           { |tic| tic.customer = other; tic.save }
    self.event_checkins.each    { |chk| chk.customer = other; chk.save }
    self.comp_tickets.each      { |tik| tik.customer = other; tik.save }
    self.waivers.each           { |wav| wav.customer = other; wav.save }
    self.event_passes.each      { |pas| pas.customer = other; pas.save }
    self.gift_certificates.each { |crt| crt.customer = other; crt.save }
    self.subscriptions.each     { |sub| sub.customer = other; sub.save }
    
    other.update( :stripe_id => self.stripe_id ) unless other.stripe_id

    return if self.wallet.nil?
    other.update( :wallet => Wallet.create ) if other.wallet.nil?
    other.wallet << self.wallet
    
  end

  def delete
    self.waivers.each { |wav| wav.delete }
    return false      unless self.can_delete?
    self.login.delete unless self.login.nil?
    super
  end

  def linked_objects
    objects = []
    objects << "Customer Has Subscription" if self.subscriptions.count > 0
    objects << "Customer Has Passes"       if self.passes.count > 0
    objects << "Customer Has Event Tics"   if self.tickets.count > 0
    objects << "Customer Has Trainings"    if self.training_passes.count > 0
    objects << "Customer Has A Wallet"     if self.wallet != nil
    objects << "Customer Has Reservations" if self.reservations.count > 0
    objects << "Customer Has Comps"        if self.comp_tickets.count > 0
    objects << "Customer Has Payments"     if self.payments.count > 0
    objects << "Customer Has Checkins"     if self.event_checkins.count > 0
    objects << "Customer Has Event Passes" if self.event_passes.count > 0
    objects << "Customer Has Waivers"      if self.waivers.count > 0
    opjects << "Customer Has Gift Certs"   if self.gift_certificates.count > 0
    objects
  end

  def can_delete?
    return self.linked_objects.count == 0
  end

  def email_login_url
    login_url       = "https://cosmicfitclub.com/auth/login"
    activation_url  = "https://cosmicfitclub.com/auth/activate?token=#{login.reset_token}"
    login.activated? ? login_url : activation_url 
  end

############################ Account/Login #############################

########################### Attribute Access ###########################

  def user
    self.login
  end

  def email
    val = super
    val.nil? ? '' : val.downcase
  end

  def after_create
    #add_passes(1,"First Class Free", "")
    create_login
  end

  def before_save
    self.email = self.email.downcase
    super
  end

  def password_set?
    return false if login.nil?
    return !login.encrypted_password.nil?
  end

  def waiver_signed?
    self.waivers.count > 0
  end

  def waiver 
    return nil unless waiver_signed?
    return waivers.sort_by(&:signed_on).last
  end

########################### Attribute Access ###########################

############################ Subscriptions #############################

  def subscription
    self.subscriptions.find { |x| !x.deactivated && !x.expired }
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
    sub_id = StripeMethods::create_subscription( plan.stripe_id, stripe_id )
    subscrip = Subscription.create(:customer_id=>self.id, :plan_id=>plan_id, :stripe_id=>sub_id )
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

  def num_passes;    wallet.nil? ? 0 : wallet.fractional_balance.to_f end

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

  def use_class_pass(reason, number=1, &block)
    self.wallet.use_pass(reason, number, &block)
  end

  def upcoming_reservations
    reservations.select { |res| res.occurrence.nil? ? false : res.occurrence.starttime > Time.now }
  end

  def buy_pack_card(pack_id, token)
    pack = Package[pack_id] or halt 403, "Can't find Pack"
    charge = StripeMethods::charge_card( token['id'], pack.price, email, pack.name, { :pack_id => pack_id } )
    self.add_payment( :stripe_id => charge.id, :amount => charge.amount , :reason =>"Bought #{pack.name}" , :type => 'new card' )
    self.add_passes( pack.num_passes, "Bought #{pack.name}", "" )
    #self.send_pack_email(pack)
  end

  def buy_pack_precharged(pack_id, payment_id)
    pack = Package[pack_id]               or raise "Can't find Pack"
    payment = CustomerPayment[payment_id] or raise "Can't find Payment"
    payment.customer_id == self.id        or raise "Payment doesn't match Customer"
    #payment.amount == pack.price          or raise "Payment doesn't match amount"
    self.add_passes( pack.num_passes, "Bought #{pack.name}", "" ) 
    #self.send_pack_email(pack)
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
    number = number.to_f
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

  def to_list_hash
    { :id => id, :name => name, :email => email }
  end

  def to_token
    self.to_list_hash
  end

  def to_list_string
    "[#{id}] #{name} (#{email})"
  end

  def staff_info
    { :id => id, :name => name, :email => email, :phone => phone, :staff => self.staff.try(:to_payout_token) }
  end

end
