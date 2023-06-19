class Payout < Sequel::Model(:payouts)

  many_to_one :payroll
  many_to_one :payroll_slip
  many_to_one :staff

end