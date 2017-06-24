class Subscription < Sequel::Model

  plugin :json_serializer

  many_to_one :customer
  many_to_one :plan

end

class MembershipUse < Sequel::Model

  plugin :json_serializer

  many_to_one :reservation, :class=>:ClassReservation, :key=>:reservation_id
  many_to_one :membership,  :class=>:Subscription, :key=>:membership_id

end