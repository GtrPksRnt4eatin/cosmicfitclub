class Subscription < Sequel::Model

  ###################### ASSOCIATIONS #####################

  many_to_one :customer
  many_to_one :plan
  one_to_many :uses, :class => :MembershipUse, :key=>:subscription_id
  many_to_many :payments, :class => :CustomerPayment, :join_table => :subscriptions_payments, :left_key => :subscription_id, :right_key => :payment_id


  ###################### ASSOCIATIONS #####################

  ####################### LIFE CYCLE ######################

  def cancel
    time_of_death = self.canceled_on || Time.now
    self.update( :canceled_on => time_of_death, :deactivated => true )
  end

  def send_email
    Mail.membership_welcome(self.customer.email, self.email_model) unless self.customer.login.activated?
    Mail.membership(self.customer.email, self.email_model)             if self.customer.login.activated?
  end

  def expired
    return false unless self.plan_id == 16
    return false unless self.canceled_on < Date.today
    self.cancel unless self.deactivated
    Slack.website_purchases(self.summary + " has expired!")
    return true    
  end

  def after_create
    super
    send_email
  end

  ####################### LIFE CYCLE ######################

  ################# CALCULATED PROPERTIES #################

  def invoices
    return [] if self.stripe_id.nil?
    invoices = Stripe::Invoice.list( subscription: self.stripe_id );
    invoices.map { |x| { :id => x["id"], :paid => x["amount_paid"], :date => DateTime.strptime(x["date"].to_s, "%s") } }
  end

  def sum_invoices
    inv = self.invoices
    return( inv == [] ? 0 : inv.sum { |x| x[:paid] } )
  end

  def price_per_class
    return self.sum_invoices if self.uses.count == 0
    self.sum_invoices / self.uses.count
  end

  def email_model
    { :name      => self.customer.name,
      :plan_name => self.plan.name,
      :login_url => self.customer.email_login_url
    }
  end

  ################# CALCULATED PROPERTIES #################

  ########################## VIEWS ########################

    def summary
      "#{customer.to_list_string} on #{plan.name}"
    end

    def details
    {  :id          => id, 
       :customer    => customer.to_list_hash,
       :plan        => plan.tokenize,
       :stripe_id   => stripe_id,
       :canceled_on => canceled_on,
       :began_on    => began_on,
       :deactivated => deactivated 
    }
  end

  def stripe_info
    return nil if self.stripe_id.nil?
    StripeMethods::get_subscription(self.stripe_id)
  end

  ########################## VIEWS ########################

  ########################## LISTS ########################

  def Subscription::list_all                               
    $DB[ %{
      SELECT subscriptions.*, customer_id, customers.name, customers.email, plan_id, plans.name AS plan_name 
      FROM Subscriptions
      LEFT JOIN customers ON customers.id = customer_id 
      LEFT JOIN plans ON plans.id = plan_id ORDER BY plans.id, deactivated, began_on
    } ].all
  end 

  ########################## LISTS ########################

end