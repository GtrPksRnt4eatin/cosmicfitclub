class EventSession < Sequel::Model

  plugin :json_serializer
  
  many_to_one :event
  one_to_many :prices, :class => :EventPrice

  def start_time; val=super; val.nil? ? nil : val.iso8601 end
  def end_time;   val=super; val.nil? ? nil : val.iso8601 end

  def <=> other
    return 0 if !start_time && !other.start_time
    return 1 if !start_time
    return -1 if !other.start_time
    start_time <=> other.start_time
  end

  def EventSession.between(from,to)
    self.order_by(:start_time).map do |sess|
      next if sess.start_time.nil?
      start = Time.parse(sess.start_time)
      next if start < from
      next if start >= to
      sess
    end.compact
  end

end