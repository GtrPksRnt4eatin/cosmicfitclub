class CustomerPayment < Sequel::Model
  
  many_to_one :customer
  many_to_one :reservation,       :class => :ClassReservation, :key => :class_reservation_id
  many_to_one :group_reservation, :class => :GroupReservation, :key => :group_reservation_id

  one_to_many :pass_transactions, :class => :PassTransaction, :key => :payment_id  
  one_to_many :tickets, :class => :EventTicket, :key => :customer_payment_id 

  def undo
    StripeMethods::refund(self.stripe_id) if self.stripe_id
    self.delete
  end

  def convert_to_passes
    self.update( :reservation => nil )
    num_passes = (self.amount.to_f / 1200).ceil
    transaction = self.customer.add_passes(num_passes, "Converted from Payment[#{self.id}] for $#{self.amount.to_f/100}", "")
    transaction.update(payment: self)
  end

  def send_notification
  	Slack.website_purchases(self.summary)   
  end

  def totals
    return StripeMethods::get_payment_totals(self.stripe_id) if self.stripe_id
    return { :gross=>amount, :fees=>0, :refunds=>0, :net=>amount }
  end

  def to_token
    { :id => self.id, :customer => self.customer.to_token, :amount => self.amount, :timestamp => self.timestamp, :stripe_id=> self.stripe_id }
  end

  def summary
  	"#{self.customer.to_list_string} - Made a $#{self.amount.to_f/100} Payment For #{self.reason}"
  end

end