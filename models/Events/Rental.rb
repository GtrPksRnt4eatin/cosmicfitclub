class Rental < Sequel::Model

  plugin :json_serializer

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

end