class GroupReservation < Sequel::Model

    many_to_one :customer

    one_to_many :slots, :class => :GroupReservationSlot

    def before_create
      self.tag = rand(36**8).to_s(36)
    end

end