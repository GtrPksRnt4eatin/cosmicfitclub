class ClassReservation < Sequel::Model

  many_to_one :customer
  many_to_one :occurrence, :class => :ClassOccurrence, :key => :class_occurrence_id
  one_to_one  :transaction, :class => :PassTransaction, :key => :reservation_id
  one_to_one  :membership_use, :class => :MembershipUse, :key => :reservation_id
  one_to_one  :payment, :class => :CustomerPayment, :key => :class_reservation_id

  def check_in
    self.checked_in = self.checked_in.nil? ? DateTime.now : nil
    self.save
  end

  def cancel
    self.transaction.undo    if self.transaction
    self.membership_use.undo if self.membership_use
    self.payment.undo        if self.payment
    self.delete
  end

  def payment_type
    return "class pass" if self.transaction
    if self.membership_use then
      return "employee" if self.membership_use.employee_discount?
      return "membership"
    end
    return "membership" if self.membership_use
    if self.payment then
      return "cash" if self.payment.type == "cash"
      return "card" if self.payment.type == "saved card"
      return "card" if self.payment.type == "new card"
    end
    return "free" if self.occurrence.free
    return ""
  end

  def <=> (other)
    self.occurrence.starttime <=> other.occurrence.starttime
  end

end