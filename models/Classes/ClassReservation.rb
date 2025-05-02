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

  def cancel(to_passes)
    self.transaction.undo          if self.transaction
    self.membership_use.undo       if self.membership_use
    self.payment.undo              if self.payment && !to_passes
    self.payment.convert_to_passes if self.payment && to_passes
    self.delete
  end

  def payment_type
    return "class pass" if self.transaction
    if self.membership_use then
      return "employee" if self.membership_use.employee_discount?
      return "membership"
    end
    if self.payment then
      return "cash" if self.payment.type == "cash"
      return "card" if self.payment.type == "saved card"
      return "card" if self.payment.type == "new card"
    end
    return "free" if self.occurrence.try(:free)
    return ""
  end

  def summary
    "#{self.customer.try(:to_list_string)} paid #{self.payment.try(:amount) || self.transaction.try(:amount)} #{self.payment_type} for #{self.occurrence.try(:summary)} on #{self.occurrence.try(:starttime)}"
  end
 
  alias :to_list_string :summary

  def <=> (other)
    self.occurrence.starttime <=> other.occurrence.starttime
  end

  def details_hash
    { :id             => self.id,
      :occurrence     => self.occurrence.try(:to_token),
      :customer       => self.customer.try(:to_token),
      :payment        => self.payment.try(:to_token),
      :transaction    => self.transaction.try(:to_token),
      :membership_use => self.membership_use.try(:to_token)
    }
  end

  def to_token
    { :id => id,
      :classname => occurrence.nil? ? "Orphaned Reservation" : occurrence.classdef.name, 
      :instructor=> occurrence.nil? ? "Some Teacher" : occurrence.teacher.name, 
      :starttime => occurrence.nil? ? Time.new : occurrence.starttime,
      :url       => "/frontdesk/class_attendance/#{occurrence.nil? ? 0 : occurrence.id}"
    } 
  end

end
