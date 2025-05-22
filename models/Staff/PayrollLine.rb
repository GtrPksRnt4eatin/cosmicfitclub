class PayrollLine < Sequel::Model(:payroll_lines)

  many_to_one :payroll_slip
  many_to_one :occurrence, :class => :ClassOccurrence

end