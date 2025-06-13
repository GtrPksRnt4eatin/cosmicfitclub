class PayrollSlip < Sequel::Model(:payroll_slips)

  many_to_one :payroll
  many_to_one :staff

  one_to_many :lines, :class => :PayrollLine
  one_to_many :payouts

  def send_email
    model = {
      :payout_total => '$%.2f' % (self.totals[:payout_total].to_i/100),
      :payroll_lines => self.postmark_lines
    }
    Mail.payout_slip( self.staff.email, model )
  end

  def details_hash
    hsh = { 
      id: self.id,
      payroll_id: self.payroll_id,
      staff: self.staff.to_payout_token
    }
    hsh[:lines] = self.lines.map(&:to_hash)
    hsh[:payouts] = self.payouts.map(&:to_hash)
    hsh[:totals] = self.totals
    hsh
  end

  def postmark_lines
    self.lines.map do |line|
      { start: line.start_time.strftime('%m/%d %H:%I%P'),
        description: line.description,
        headcount: line.occurrence ? line.occurrence.headcount : 0,
        value: '$%.2f' % (line.value.to_i/100)
      }
    end
  end
 
  def totals
    { :payout_total => self.lines.inject(0) { |sum,x| sum + (x.value        || 0) },
      :cosmic_total => self.lines.inject(0) { |sum,x| sum + (x.cosmic       || 0) },
      :loft_total   => self.lines.inject(0) { |sum,x| sum + (x.loft         || 0) },
      :loft_rentals => self.lines.inject(0) { |sum,x| sum + (x.loft_rentals || 0) },
      :loft_classes => self.lines.inject(0) { |sum,x| sum + (x.loft_classes || 0) }
    }
  end

end