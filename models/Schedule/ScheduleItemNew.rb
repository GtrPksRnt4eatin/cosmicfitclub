class ScheduleItemNew < Sequel::Model

    def icecube_schedule
        IceCube::Schedule.from_yaml(self.icecube_yaml) 
    end

    def get_occurrences(from,to)
        return [] if self.icecube_yaml.nil?
        schedule = self.icecube_schedule or return []
        from = Time.parse(from) if from.is_a? String
        to = Time.parse(to) if to.is_a? String
        schedule.occurrences_between(from.to_time,to.to_time)
    end

end