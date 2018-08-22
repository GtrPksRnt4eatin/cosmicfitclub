class Rental < Sequel::Model
  
  def end_time
    self.start_time + self.duration_hours.hours
  end

  def Rental.between(from,to)
    self.order_by(:start_time).map do |evt|
      next if evt.start_time.nil?
      start = evt.start_time
      next if start < from
      next if start >= to
      evt
    end.compact
  end

  def Rental.upcoming
    Rental.where{ start_time > Date.today.to_time }.order(:start_time)
  end

  def Rental.past
    Rental.where{ start_time < Date.today.to_time }.order(:start_time)
  end

end