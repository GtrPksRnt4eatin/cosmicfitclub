class Rental < Sequel::Model

  def after_create
    super
    Slack.website_scheduling("Private Rental Added: #{ self.description }")
  end
  
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

  def schedule_details_hash
    { :type => 'private',
      :day => Date.strptime(start_time.to_s).to_s,
      :starttime => Time.parse(start_time.to_s),
      :endtime => end_time,
      :title => title
    }
  end

  def description
    "#{ time_12h(self.start_time) } - #{ self.title }"
  end

  def time_12h(val) 
    Time.parse(val.to_s).strftime("%Y %b %-d @ %I:%M %P") rescue val 
  end

end