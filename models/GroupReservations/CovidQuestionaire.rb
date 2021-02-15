class CovidQuestionaire < Sequel::Model

  many_to_one :customer
  one_to_one :checkin, :class => :GroupReservationCheckin


end