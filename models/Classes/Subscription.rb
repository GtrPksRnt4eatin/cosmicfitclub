class Subscription < Sequel::Model

  plugin :json_serializer

  many_to_one :customer
  many_to_one :plan
  one_to_many :uses, :class => :MembershipUse, :key=>:membership_id

  def cancel
    self.update( :canceled_on => Time.now, :deactivated => true )
  end

  def stripe_info
    StripeMethods::get_subscription(self.stripe_id)
  end

end

class MembershipUse < Sequel::Model

  plugin :json_serializer

  many_to_one :reservation, :class=>:ClassReservation, :key=>:reservation_id
  many_to_one :membership,  :class=>:Subscription, :key=>:membership_id

  def undo
  	self.delete
  end

  def employee_discount?
    self.membership.plan.id == 10
  end

end