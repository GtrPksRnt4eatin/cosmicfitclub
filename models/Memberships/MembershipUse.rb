class MembershipUse < Sequel::Model

  many_to_one :reservation, :class=>:ClassReservation, :key=>:reservation_id
  many_to_one :membership,  :class=>:Subscription, :key=>:subscription_id

  def undo
  	self.delete
  end

  def employee_discount?
    self.membership.plan.id == 10
  end

end