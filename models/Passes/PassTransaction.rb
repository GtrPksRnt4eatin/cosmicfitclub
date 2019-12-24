class PassTransaction < Sequel::Model

  many_to_one :reservation, :class => :ClassReservation, :id => :reservation_id
  many_to_one :wallet
  one_to_many :comps, :class => :CompTicket

  def before_create
    self.timestamp = Time.now
    super
  end

  def undo
    self.wallet.update( :pass_balance => self.wallet.pass_balance - self.delta )
    self.delete
  end
  
  def customer
    arr = wallet.try(:customers) or return nil
    arr[0]
  end

end