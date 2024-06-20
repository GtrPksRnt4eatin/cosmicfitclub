class EventSession < Sequel::Model

  ###################### ASSOCIATIONS #####################
  
  many_to_one :event
  one_to_many :passes, :class=>:EventPass,  :key => :session_id

  ###################### ASSOCIATIONS #####################

  ##################### CLASS METHODS #####################

  def EventSession.between(from,to)
    from = Time.parse(from) if from.is_a? String
    from = from.to_time     if from.is_a? Date
    to   = Time.parse(to)   if to.is_a? String
    to   = to.to_time       if to.is_a? Date
    self.order(:start_time).map do |sess|
      next if sess.start_time.nil?
      start = Time.parse(sess.start_time)
      next if start < from
      next if start >= to
      next if sess.event.hidden
      sess
    end.compact
  end

  ##################### CLASS METHODS #####################

  ####################### LIFE CYCLE ######################

  def linked_objects
    objects = []
    objects << "Session Has Tickets" if self.tickets.count > 0
    objects
  end

  def can_delete?
    return self.linked_objects.count == 0
  end

  def delete
    return false unless self.can_delete?
    super
  end

  ####################### LIFE CYCLE ######################

  #################### ATTRIBUTE ACCESS ###################

  def start_time; val=super; val.nil? ? nil : val.iso8601 end
  def end_time;   val=super; val.nil? ? nil : val.iso8601 end

  def tickets
    EventTicket.where(Sequel.lit("included_sessions @> ARRAY[?::bigint]", self.id)).all
  end

  def capacity
    super || 20
  end

  def headcount
    self.passes.count
  end

  #################### ATTRIBUTE ACCESS ###################

  ################# CALCULATED PROPERTIES #################

  def duration_sec
    Time.parse(end_time) - Time.parse(start_time)
  end

  def duration_ical
    "P#{Time.at(duration_sec).utc.hour}H#{Time.at(duration_sec).utc.min}M#{Time.at(duration_sec).utc.sec}S"
  end

  ################# CALCULATED PROPERTIES #################

  ######################## SORTING ########################

  def <=> other
    return 0 if !start_time && !other.start_time
    return 1 if !start_time
    return -1 if !other.start_time
    start_time <=> other.start_time
  end

  ######################## SORTING ########################

  ########################## VIEWS ########################

  def to_token
    { :id => self.id, :start_time => self.start_time, :title => self.title }
  end

  def schedule_details_hash
    return nil unless event
    { :type               => 'eventsession',
      :day                => Date.strptime(start_time).to_s,
      :starttime          => Time.parse(start_time),
      :endtime            => Time.parse(end_time),
      :title              => title,
      :event_title        => event.name,
      :event_id           => event_id,
      :thumb_url          => event.thumb_url,
      :multisession_event => event.sessions.count > 1
    }
  end

  def attendance_hash
    { :id          => self.id,
      :event_id    => self.event_id,
      :start_time  => self.start_time,
      :end_time    => self.end_time,
      :title       => self.title,
      :description => self.description,
      :passes      => self.passes.sort_by(&:ticket_id).map(&:attendance_hash)
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

  ########################## VIEWS ########################
end
