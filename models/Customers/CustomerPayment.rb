class CustomerPayment < Sequel::Model
  
  many_to_one :customer
  many_to_one :reservation, :class => :ClassReservation, :key => :class_reservation_id
  
  one_to_many :tickets, :class => :EventTicket, :key => :customer_payment_id 
  one_to_many :group_slots, :class => :GroupReservationSlot

  def undo
    StripeMethods::refund(self.stripe_id) if self.stripe_id
    self.delete
  end

  def convert_to_passes
    self.update( :reservation => nil )
    num_passes = (self.amount / 1200).ceil
    self.customer.add_passes(num_passes, "Converted from Payment[#{self.id}] for $#{self.amount.to_f/100}", "")
  end

  def send_notification
  	Slack.website_purchases(self.summary)   
  end

  def to_token
    { :id => self.id, :amount => self.amount, :timestamp => self.timestamp, :stripe_id=> self.stripe_id }
  end

  def summary
  	"#{self.customer.to_list_string} - Made a $#{self.amount.to_f/100} Payment For #{self.reason}"
  end

end