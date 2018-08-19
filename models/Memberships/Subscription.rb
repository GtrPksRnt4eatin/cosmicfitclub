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

end