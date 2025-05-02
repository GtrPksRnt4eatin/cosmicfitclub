class PassTransaction < Sequel::Model

  many_to_one :reservation, :class => :ClassReservation, :id => :reservation_id
  many_to_one :group_reservation, :class => :GroupReservation, :id => :group_reservation_id
  many_to_one :wallet
  one_to_many :comps, :class => :CompTicket

  def before_create
    self.timestamp = Time.now
    super
  end

  def undo
    self.wallet.update( :pass_balance => self.wallet.pass_balance - self.delta )
    self.wallet.update( :fractional_balance => self.wallet.fractional_balance - self.delta_f )
    self.delete
  end
  
  def customer
    arr = wallet.try(:customers) or return nil
    arr[0]
  end

  def to_token
    { :id => self.id,
      :delta => self.delta,
      :delta_f => self.delta_f,
      :timestamp => self.timestamp,
      :description => self.description
    }
  end

end