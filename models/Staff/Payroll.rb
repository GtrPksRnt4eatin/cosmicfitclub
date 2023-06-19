
class Payroll < Sequel::Model(:payrolls)

  one_to_many :slips, :class => :PayrollSlip

  PAY_PERIODS_ICAL = "DTSTART;TZID=EST:20170105T000000\nRRULE:FREQ=WEEKLY;INTERVAL=2"

  def Payroll::Schedule 
    IceCube::Schedule.from_ical(PAY_PERIODS_ICAL)
  end

  def Payroll::prev_period_starts(num)
    Payroll::Schedule.previous_occurrences(num,Date.today)
  end

  def Payroll::next_period_starts(num)
    Payroll::Schedule.next_occurrences(num,Date.today)
  end

  # 1st & 16th schedule
  def Payroll::get_last_period
    now = DateTime.now
    period_start, period_end = nil, nil
    if now.day < 16 then
      period_start = now.month == 1 ? now.change(year: now.year-1, month: 12) : now.change(month: now.month-1)
      period_start = period_start.change(day: 16, hour: 0)
      period_end   = now.change(day: 1, hour: 0)
    else
      period_start, period_end = now.change(day: 1, hour: 0), now.change(day: 16, hour: 0)
    end
    { :from => period_start, :to => period_end - 0.00001 }
  end

  def details_hash
    hsh = self.to_hash
    hsh[:slips]   = slips.map(&:details_hash)
    hsh[:payouts] = Payout.where(payroll_id: self.id).all.map(&:to_hash)
    hsh[:totals]  = self.totals
    hsh
  end

  def totals
    self.slips.map(&:totals).inject { |sum,x| sum.merge(x){ |k,x,y| x+y } }
  end

  def full_delete
    self.slips.each do |slip|
      slip.lines.each do |line|
        line.delete
      end
      slip.delete
    end
    self.delete
  end

end