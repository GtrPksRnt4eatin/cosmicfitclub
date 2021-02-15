class GroupReservation < Sequel::Model

    many_to_one :customer

    one_to_many :slots, :class => :GroupReservationSlot
end