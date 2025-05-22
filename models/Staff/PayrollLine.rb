class PayrollLine < Sequel::Model(:payroll_lines)

  many_to_one :payroll_slip
  many_to_one :occurrence, :class => :ClassOccurrence, :key => :class_occurrence_id

  def to_hash
    hsh = { 
      id: self.id,
      description: self.description,
      start_time: self.start_time,
      end_time: self.end_time,
      value: self.value,
      cosmic: self.cosmic,
      loft: self.loft,
      loft_rentals: self.loft_rentals,
      loft_classes: self.loft_classes
    }
    hsh[:occurrence] = self.occurrence.to_hash if self.occurrence
    hsh[:staff] = self.staff.to_payout_token if self.staff
    hsh
  end

end