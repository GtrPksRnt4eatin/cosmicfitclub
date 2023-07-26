class GroupReservationSlot < Sequel::Model

    many_to_one :customer
    many_to_one :reservation, :class => :GroupReservation,        :key => :reservation_id
    many_to_one :payment,     :class => :CustomerPayment,         :key => :payment_id
    one_to_one  :checkin,     :class => :GroupReservationCheckin, :key => :slot_id

    def details_view
      hsh = self.to_hash
      hsh[:customer] = self.customer.try(:to_token)
      hsh[:payment]  = self.payment.try(:to_hash)
      hsh[:checkin]  = self.checkin.try(:to_hash)
      hsh
    end
end