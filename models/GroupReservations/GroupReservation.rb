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
          next if res.start_time < from
          next if res.start_time >= to
          res
        end.compact
    end

    def to_public_daypilot
      {
        :start => self.start_time.strftime("%Y/%m/%dT%H:%M:%S"),
        :end   => self.end_time.strftime("%Y/%m/%dT%H:%M:%S"),
        :text  => "Reserved",
        :id    => self.id
      }
    end

    def to_admin_daypilot
      text = slots.map { |s| s.customer.nil? ? "TBD" : s.customer.to_list_string }.join(',')
      {
        :start => self.start_time.strftime("%Y/%m/%dT%H:%M:%S"),
        :end   => self.end_time.strftime("%Y/%m/%dT%H:%M:%S"),
        :text  => text,
        :id    => self.id
      }
    end

    def details_view
      hsh = self.to_h
      hsh.customer = self.customer.to_token
      hsh.slots = self.slots.map{&:details_view)
      hsh
    end
end