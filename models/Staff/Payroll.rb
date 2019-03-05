
class Payroll 

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

end