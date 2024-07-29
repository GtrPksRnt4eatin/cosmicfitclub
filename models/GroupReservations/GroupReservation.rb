class GroupReservation < Sequel::Model

  many_to_one :customer
  one_to_many :slots, :class => :GroupReservationSlot
  one_to_many :payments, :class => :CustomerPayment

  def GroupReservation.all_between(from,to) 
    from = Time.parse(from) if from.is_a? String
    to   = Time.parse(to)   if   to.is_a? String
    self.order(:start_time).map do |res|
      next if res.start_time.nil?
      next if res.start_time < from
      next if res.start_time >= to
      res
    end.compact
  end

  def full_delete
    self.slots.each { |s| s.delete }
    self.delete
  end

  def before_create
    self.tag = rand(36**8).to_s(36)
  end

  def after_create
    publish_gcal_event
  end

  def publish_gcal_event
    if self.gcal_event_id then
      Calendar::update_event(self.gcal_event_id) do |event|
        event.summary = self.customer_string
        event.start.datetime = start_time.iso8601
        event.end.datetime = end_time.iso8601
      end
    else
      event_id = Calendar::create_point_rental(start_time, end_time, customer_string)
      self.update( :gcal_event_id => event_id )
    end
  end

  #################### CALCULATED PROPERTIES ####################
  
  def duration_sec
    self.end_time - self.start_time
  end
  
  def duration_ical
    "P#{Time.at(duration_sec).utc.hour}H#{Time.at(duration_sec).utc.min}M#{Time.at(duration_sec).utc.sec}S"
  end
  
  #################### CALCULATED PROPERTIES ####################

  ############################ VIEWS ############################

  def customer_string
    return customer.to_list_string if slots.count == 0
    slots.map { |s| s.customer.nil? ? "TBD" : s.customer.to_list_string }.join(',')
  end

  def summary
    "#{duration_sec / 60} Min Group Reservation #{self.start_time.strftime("%Y/%m/%d %H:%M")} #{customer_string}"
  end

  def to_public_daypilot
    { :start => self.start_time.strftime("%Y/%m/%dT%H:%M:%S"),
      :end   => self.end_time.strftime("%Y/%m/%dT%H:%M:%S"),
      :text  => "Reserved",
      :id    => self.id
    }
  end

  def to_admin_daypilot
    { :start => self.start_time.strftime("%Y/%m/%dT%H:%M:%S"),
      :end   => self.end_time.strftime("%Y/%m/%dT%H:%M:%S"),
      :text  => customer_string,
      :id    => self.id
    }
  end

  def to_ical_event
    ical = Icalendar::Event.new
    ical.dtstart = DateTime.parse(self.start_time.to_s)
    ical.duration = self.duration_ical
    ical.summary = customer.to_list_string
    ical
  end

  def details_view
    hsh = self.to_hash
    hsh[:customer] = self.customer.to_token
    hsh[:slots]    = self.slots.map(&:details_view)
    hsh[:payments] = self.payments.map(&:to_token)
    hsh
  end

  ############################ VIEWS ############################

end
