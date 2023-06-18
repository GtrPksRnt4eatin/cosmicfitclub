class PayrollSlip < Sequel::Model(:payroll_slips)

  many_to_one :payroll
  one_to_many :lines, :class => :PayrollLine

  def details_hash
    hsh = self.to_hash
    hsh[:lines] = self.lines.map(&:to_hash)
    hsh[:totals] = self.totals
    hsh
  end

  def totals
    { :payout_total => self.lines.inject(0) { |sum,x| sum + x.value },
      :cosmic_total => self.lines.inject(0) { |sum,x| sum + x.cosmic },
      :loft_total   => self.lines.inject(0) { |sum,x| sum + x.loft }
    }
  end

end