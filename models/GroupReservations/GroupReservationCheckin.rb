class GroupReservationCheckin < Sequel::Model

    many_to_one :questionaire, :model => :CovidQuestionaire, :key => :questionaire_id
    many_to_one :slot, :model => :GroupReservationSlot, :key => :slot_id

end