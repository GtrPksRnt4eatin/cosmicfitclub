class HourlyPunch < Sequel::Model
	
  many_to_one :customer
  many_to_one :staff
  many_to_one :hourly_task

  ##################################### CLASS METHODS #######################################

  def HourlyPunch::between(start,end)
    HourlyPunch.where(starttime: Date.parse(start)...Date.parse(end)).all
  end
 
  def HourlyPunch::open_punch(custy_id)
    HourlyPunch[ :customer_id => custy_id, :endtime => nil ]
  end

  def HourlyPunch::punched_in?(custy_id)
    !! HourlyPunch::open_punch(custy_id)
  end

  def HourlyPunch::punched_out?(custy_id)
    ! HourlyPunch::open_punch(custy_id)
  end

  def HourlyPunch::punches(custy_id)
    HourlyPunch.where( :customer_id => custy_id ).order_by(:starttime).all
  end

  def HourlyPunch::punch_in(customer_id, hourly_task_id)
    HourlyPunch.create( 
  	  :customer_id => customer_id, 
  	  :hourly_task_id => hourly_task_id,
  	  :starttime => Time.now
  	)
  end

  def HourlyPunch::punch_out(customer_id)
    punch = HourlyPunch::open_punch(customer_id) or return nil
    punch.close
  end

  ##################################### CLASS METHODS #######################################

  ################################### INSTANCE METHODS ######################################

  def close; self.update( :endtime   => Time.now ) end

  def closed?; !self.endtime.nil? end

  def duration
    out = self.closed? ? self.rounded_end.to_f : Time.now.to_f
    ( out - self.rounded_start.to_f ) / 60 / 60
  end

  def rounded_start
    Time.at( ( self.starttime.to_f / (60*15) ).round * (60*15) )
  end

  def rounded_end
    Time.at( ( self.endtime.to_f / (60*15) ).round * (60*15) )
  end

  ################################### INSTANCE METHODS ######################################

end