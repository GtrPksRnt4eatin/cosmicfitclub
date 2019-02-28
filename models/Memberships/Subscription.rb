class Subscription < Sequel::Model

  many_to_one :customer
  many_to_one :plan
  one_to_many :uses, :class => :MembershipUse, :key=>:subscription_id

  def cancel
    self.update( :canceled_on => Time.now, :deactivated => true )
  end

  def stripe_info
    return nil if self.stripe_id.nil?
    StripeMethods::get_subscription(self.stripe_id)
  end

  def invoices
    return [] if self.stripe_id.nil?
    invoices = Stripe::Invoice.list( customer: self.customer.stripe_id )
    invoices = invoices.select { |x| x["subscription"] == self.stripe_id }
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

  def Subscription::list_all_grouped
    $DB[ %{
      SELECT subscriptions.*, customer_id, customers.name, customers.email, plan_id, plans.name AS plan_name 
      FROM Subscriptions
      LEFT JOIN customers ON customers.id = customer_id 
      JOIN plans ON plans.id = plan_id ORDER BY plans.id, deactivated
    } ].all
  end 

end