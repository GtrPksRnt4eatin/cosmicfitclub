class GroupReservation < Sequel::Model

    many_to_one :customer

    one_to_many :slots, :class => :GroupReservationSlot

    def before_create
      self.tag = rand(36**8).to_s(36)
    end

    def GroupReservation.all_between(from,to) 
      from = Time.parse(from) if from.is_a? String
      to   = Time.parse(to)   if   to.is_a? String
      self.order(:start_time).map do |res|
        next if res.start_time.nil?
        start = Time.parse(res.start_time)
        next if start < from
        next if start >= to
        {
          :start => res.start_time,
          :end   => res.end_time,
          :text  => "Reserved",
          :id    => res.id
        }
      end.compact
    end
    
end