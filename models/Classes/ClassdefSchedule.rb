class ClassdefSchedule < Sequel::Model
  
  plugin :pg_array_associations
  pg_array_to_many :teachers, :key => :instructors, :class => :Staff

  many_to_one :classdef, :key => :classdef_id, :class => :ClassDef
  one_to_many :exceptions, :key => :class_schedule_id, :class => :ClassException

  many_to_one :image, :key => :image_id, :class=>:StoredImage
  many_to_one :video, :key => :video_id, :class=>:StoredImage
  many_to_one :location

  def ClassdefSchedule.find_matching_schedule(occurrence)
    ClassdefSchedule.where(classdef_id: occurrence.classdef_id).each do |sched|
      return sched if sched.matches_occurrence? occurrence
    end
    return nil
  end

  def ClassdefSchedule.get_all_occurrences(from,to)
    items = []
    ClassdefSchedule.all.each do |sched|
      sched.get_occurrences(from, to).each do |starttime|
        exception = ClassException.find( :classdef_id => sched.classdef.id, :original_starttime => starttime.to_time.iso8601 )
        items << { 
          :day => Date.strptime(starttime.to_time.iso8601).to_s,
          :starttime => starttime,
          :endtime =>  starttime + ( sched.end_time - sched.start_time ),
          :title => sched.classdef.name,
          :classdef_id => sched.classdef.id,
          :sched_id => sched.id,
          :instructors => exception.try(:teacher) ? [exception.teacher] : sched.teachers,
          :exception => exception.try(:full_details)
        }
      end
    end
    items
  end

  def ClassdefSchedule.get_all_occurrences_with_exceptions_merged(from,to)
    items = []
    ClassdefSchedule.all.each do |sched|
      sched.get_occurrences_with_exceptions_merged(from, to).each do |occ|
        items << { 
          :day => Date.strptime(occ[:starttime].to_time.iso8601).to_s,
          :starttime => occ[:starttime],
          :endtime =>  occ[:starttime] + ( sched.end_time - sched.start_time ),
          :title => sched.classdef.name,
          :classdef_id => sched.classdef.id,
          :thumb_url => occ[:thumb_url],
          :sched_id => sched.id,
          :instructors => occ[:instructors],
          :exception => occ[:exception].try(:full_details),
          :location => occ[:location] || sched.location
        }
      end
    end
    items
  end

  def ClassdefSchedule.get_class_page_rankings
    items = []
    from = DateTime.now
    to = from.next_day(7)
    ClassdefSchedule.all.each do |sched|
      sched.get_occurrences(from,to).each do |starttime|
        items << { :starttime => starttime, :classdef => sched.classdef.to_token }
      end
    end
    items.reject!{ |x| x[:starttime] < DateTime.now }
    items.sort_by!{ |x| x[:starttime] }
    items.map!{ |x| x[:classdef][:id] }
    items.uniq!
    items | ClassDef.list_active_and_current.map(&:id)
  end

  def icecube_schedule
    IceCube::Schedule.new(self.start_time) do |sched|
      sched.add_recurrence_rule IceCube::Rule.from_ical(self.rrule)
    end
  end

  def icecube_past_schedule(start)
    s = Time.parse(start.strftime("%Y-%m-%d ") + self.start_time.to_s)
    IceCube::Schedule.new(s) do |sched|
      sched.add_recurrence_rule IceCube::Rule.from_ical(self.rrule)
    end
  end

  def next_occurrence(from=nil)
    self.icecube_schedule.next_occurrence(from)
  end

  def get_occurrences(from,to)
    return [] if rrule.nil?
    return [] if start_time.nil?
    from = Time.parse(from) if from.is_a? String
    to = Time.parse(to) if to.is_a? String
    self.icecube_schedule.occurrences_between(from.to_time,to.to_time)
  end

  def matches_occurrence?(occ)
    return false if Sequel::SQLTime.parse(occ.starttime.to_s).to_s != self.start_time.to_s
    self.icecube_past_schedule(occ.starttime).occurs_at? occ.starttime
  end

  def get_occurrences_with_exceptions(from,to)
    get_occurrences(from,to).map do |starttime|
      exception  =  ClassException.find( :classdef_id => self.classdef.id, :original_starttime => starttime.to_time.iso8601 )
      occurrence = ClassOccurrence.find( :classdef_id => self.classdef_id, :starttime          => starttime.to_time.iso8601 )
      { :sched_id    => self.id,
        :type        => 'classoccurrence',
        :day         => Date.strptime(starttime.to_time.iso8601).to_s,
        :starttime   => starttime.to_time,
        :endtime     => starttime + ( self.end_time - self.start_time ),
        :title       => self.classdef.name,
        :classdef    => self.classdef.to_token,
        :location    => self.location.try(:to_token) ||  classdef.location.try(:to_token) || { :id=>4, :name=>"Cosmic Fit Club (original)" },
        :instructors => self.teachers.map(&:to_token),
        :capacity    => self.capacity,
        :headcount   => 0,
        :thumb_url   => self.thumb_url,
        :scheduled   => { :starttime => starttime.to_time.iso8601, :teachers => self.teachers.map(&:to_token) },
        :occurrence  => occurrence.try(:to_hash),
        :exception   => exception.try(:full_details),
        :allow_free  => self.allow_free,
        :virtual     => self.virtual
      }
    end
  end

  def get_occurrences_with_exceptions_merged(from,to)
    get_occurrences_with_exceptions(from,to).map do |occ|
      next occ if occ[:exception].nil?
      next nil if occ[:exception][:changes][:cancelled]
      if occ[:exception][:changes][:sub] then
        sub = Staff[occ[:exception][:changes][:sub][:id]]
        occ[:instructors]  = [sub.to_token]
        occ[:thumb_url]    = sub.thumb_url
      end
      occ[:starttime]    = occ[:exception][:changes][:starttime]     unless occ[:exception][:changes][:starttime].nil?
      occ[:endtime]      = occ[:exception][:changes][:endtime]       unless occ[:exception][:changes][:endtime].nil?
      next occ      
    end.compact
  end

  def get_exception_dates
    exceptions
  end

  def duration_sec;          end_time - start_time                            end
  def rrule_english;         IceCube::Rule.from_ical(rrule).to_s              end
  def start_time_12hr;       Time.parse(start_time.to_s).strftime("%I:%M %P") rescue start_time end
  def start_time_12hr_short; Time.parse(start_time.to_s).strftime("%l:%M %P") rescue start_time end
  def end_time_12hr;         Time.parse(end_time.to_s).strftime("%I:%M %P")   rescue end_time   end

  def capacity
    super || classdef.capacity
  end

  def duration
    self.end_time - self.start_time
  end

  def img_url
    self.image.try(:image_url) || self.classdef.try(:image_url,:medium) || self.teachers[0].try(:image_url,:medium) 
  end

  def thumb_url
    self.img_url
  end

  ###################################### VIEWS #######################################

  # ie: Mon @ 12:30 pm 
  def simple_meeting_time_description
    match = /Weekly on (\S+?)(nes|rs|s)*+(ur)?days/.match(rrule_english) or return ""
    match[1] + " @ " + start_time_12hr_short    
  end
  
  # ie: Mon @  5:00 pm w/ Tim Leibowitz
  def simple_meeting_time_description_with_staff(spaced=true)
    match = /Weekly on (\S+?)(nes|rs|s)*+(ur)?days/.match(rrule_english) or return ""
    divider = (spaced ? "   " : "") + " w/ " + (spaced ? "  " : "")
    teacher = spaced ? self.teachers[0].name.ljust(18).truncate(18) : self.teachers[0].name
    match[1] + " @ " + start_time_12hr_short + divider + teacher
  end

  def description_line
    "#{classdef.name} w/ #{teachers.map(&:name).join(", ")} #{rrule_english} @ #{start_time_12hr}"
  end

  def full_description
    "#{classdef.name} w/ #{teachers.map(&:name).join(", ")} #{rrule_english} #{start_time_12hr} - #{end_time_12hr}"
  end

  def teacher_names
    teachers.map(&:name).join(", ")
  end

  def poster_lines(spaced=false)
    arr = []
    arr << classdef.name
    arr << simple_meeting_time_description_with_staff(spaced)
  end

  def details_hash
    { :id => id,
      :classdef   => classdef.to_token,
      :teachers   => teachers.map(&:to_token),
      :rrule      => rrule_english,
      :start_time => start_time_12hr,
      :capacity   => capacity,
      :image_url  => self.image.try(:image_url),
      :video_url  => self.video.try(:image_url),
    }
  end

  def schedule_details_hash
    { :type        => 'classoccurrence',
      :sched_id    => self.id,
      :duration    => self.duration_sec,
      :classdef_id => self.classdef.id,
      :title       => self.classdef.name,
      :instructors => self.teachers.map(&:to_token),
      :capacity    => self.capacity,
      :image_url   => self.image.try(:image_url),
      :allow_free  => self.allow_free
    }
  end

  def to_ical_event
    ical = Icalendar::Event.new
    dtstart = next_occurrence.to_date
    ical.dtstart = DateTime.parse(dtstart.to_s + "T" + start_time.to_s)
    ical.duration = "P#{Time.at(duration_sec).utc.hour}H#{Time.at(duration_sec).utc.min}M#{Time.at(duration_sec).utc.sec}S"
    ical.rrule = rrule
    ical.summary = "#{classdef.name} w/ #{teachers.map(&:name).join(', ')}"
    ical
  end

  ###################################### VIEWS #######################################

end