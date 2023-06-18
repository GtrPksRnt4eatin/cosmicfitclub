class PayrollSlip < Sequel::Model(:payroll_slips)

  many_to_one :payroll
  many_to_one :staff
  one_to_many :lines, :class => :PayrollLine


  def details_hash
    hsh = { 
      id: self.id,
      payroll_id: self.payroll_id,
      staff: self.staff.to_token
    }
    hsh[:lines] = self.lines.map(&:to_hash)
    hsh[:totals] = self.totals
    hsh
  end

  def totals
    { :payout_total => self.lines.inject(0) { |sum,x| sum + (x.value  || 0) },
      :cosmic_total => self.lines.inject(0) { |sum,x| sum + (x.cosmic || 0) },
      :loft_total   => self.lines.inject(0) { |sum,x| sum + (x.loft   || 0) }
    }
  end

end