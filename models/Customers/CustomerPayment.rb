class CustomerPayment < Sequel::Model
  
  many_to_one :customer
  many_to_one :reservation, :class => :ClassReservation, :key => :class_reservation_id

  def undo
    StripeMethods::refund(self.stripe_id) if self.stripe_id
    self.delete
  end

end