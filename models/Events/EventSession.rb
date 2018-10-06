class EventSession < Sequel::Model
  
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

  def schedule_details_hash
    return nil unless event
    { :type => 'eventsession',
      :day => Date.strptime(start_time).to_s,
      :starttime => Time.parse(start_time),
      :endtime => Time.parse(end_time),
      :title => title,
      :event_title => event.name,
      :event_id => event_id,
      :multisession_event => event.sessions.count > 1
    }
  end

  def to_ical_event
    return nil unless event
    ical = Icalendar::Event.new
    ical.dtstart = DateTime.parse(start_time.to_s)
    ical.duration = duration_ical
    ical.summary = ( event.multisession? ? "#{event.name} - #{title}" : "#{event.name}" )
    ical
  end

  def duration_sec
    end_time - start_time
  end

  def duration_ical
    "P#{Time.at(duration_sec).utc.hour}H#{Time.at(duration_sec).utc.min}M#{Time.at(duration_sec).utc.sec}S"
  end

end