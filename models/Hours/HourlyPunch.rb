class HourlyPunch < Sequel::Model
	
  many_to_one :customer
  many_to_one :staff
  many_to_one :hourly_task

end