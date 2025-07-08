class GroupReservation < Sequel::Model

  many_to_one :customer
  one_to_many :slots, :class => :GroupReservationSlot
  one_to_many :payments, :class => :CustomerPayment

  def GroupReservation.check_for_conflict(from,to)
    from = Time.parse(from) if from.is_a? String
    to   = Time.parse(to)   if   to.is_a? String
    self.where( start_time: from..to, end_time: from..to ).first
  end

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

  def GroupReservation.upcoming_for(customer_id)
    GroupReservationSlot.where(:customer_id=>customer_id).where(:start_time => Date.today..nil).all.map(&:reservation).map(&:to_token)
  end

  def GroupReservation.update_from_gcal(change)
    res = GroupReservation.where(:gcal_event_id => change[:id]).first or return
    if change[:status] == "cancelled" 
      res.full_delete
    else 
      res.update(:start_time=>change[:start], :end_time=>change[:end])
    end
  end

  def full_delete
    Slack.website_purchases("#{self.summary} Cancelled!")
    Calendar::delete_event(self.gcal_event_id)
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
        event.start.date_time = start_time.iso8601
        event.end.date_time = end_time.iso8601
        event
      end
    else
      event_id = Calendar::create_point_rental(start_time, end_time, customer_string)
      self.update( :gcal_event_id => event_id )
    end
  end

  def send_confirmation_emails
    model = {
      :duration => "#{(self.duration_sec/60).to_i} minute",
      :start => self.start_time.strftime("%a %b %d %Y @ %l:%M %P"),
      :participants => self.customer_string,
      :confirmation => self.tag
    }
    slots.each do |s|
      next if s.customer.nil?
      Mail.point_reservation(s.customer.email, model)
    end
  end

  def send_slack_notification
    Slack.website_purchases(self.summary)
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
    return customer.name if slots.count == 0
    slots.map { |s| s.customer.nil? ? "TBD" : s.customer.name }.join(', ')
  end

  def summary
    "#{(duration_sec / 60).to_i} Min on #{self.start_time.strftime("%a %b %d %Y @ %l:%M %P")} for #{customer_string}"
  end

  def to_public_daypilot(logged_in=nil)
    show_text = self.customer_id == logged_in
    { :start => self.start_time.strftime("%Y/%m/%dT%H:%M:%S"),
      :end   => self.end_time.strftime("%Y/%m/%dT%H:%M:%S"),
      :text  => show_text ? customer_string : "Reserved",
      :id    => self.id,
      :gcal  => self.gcal_event_id,
      :resource => "Loft-1F-Front (4)"
    }
  end

  def to_admin_daypilot
    { :start  => self.start_time.strftime("%Y-%m-%dT%H:%M:%S"),
      :end    => self.end_time.strftime("%Y-%m-%dT%H:%M:%S"),
      :text   => customer_string,
      :id     => self.id,
      :gcal   => self.gcal_event_id,
      :source => "group_reservation",
      :resource => "Loft-1F-Front (4)"
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

  def to_token
    { :id => self.id,
      :summary => self.summary
    }
  end

  ############################ VIEWS ############################

end
