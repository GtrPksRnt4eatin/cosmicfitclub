class MembershipUse < Sequel::Model

  many_to_one :reservation,  :class=>:ClassReservation, :key=>:reservation_id
  many_to_one :membership,   :class=>:Subscription,     :key=>:subscription_id
  many_to_one :subscription, :class=>:Subscription,     :key=>:subscription_id

  def undo
  	self.delete
  end

  def employee_discount?
    self.subscription.plan.id == 10
  end

  def to_token
    { :id => self.id,
      :timestamp => self.datetime,
      :reason => self.reason
    }
  end

end