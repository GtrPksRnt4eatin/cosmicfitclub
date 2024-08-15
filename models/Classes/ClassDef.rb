require 'ice_cube'
require 'active_support/core_ext/numeric/time.rb'

class ClassDef < Sequel::Model

  include PositionAndDeactivate
  include ImageUploader[:image]

  one_to_many :schedules,   :class => :ClassdefSchedule, :key => :classdef_id 
  one_to_many :occurrences, :class => :ClassOccurrence,  :key => :classdef_id
  one_to_many :exceptions,  :class => :ClassException,   :key => :classdef_id

  many_to_one :location

  ####################### LISTS ############################

  def ClassDef.list_active_and_current
    ClassDef.list_active.select! { |x| x.schedules.count > 0 }
  end

  def ClassDef.list_active
    ClassDef.exclude(:deactivated=>true).order(:position).all
  end

  def ClassDef.list_scheduled
    ClassDef.all.select{ |x| x.schedules.count > 0 }
  end

  def ClassDef.list_all
    all.map(&:to_token)
  end

  ####################### LISTS ############################

  def after_save
  	self.id
  	super
  end

  def deactivate
    return false unless self.schedules == []
    super
  end
  
  def thumb(size=:small)
    return nil              if self.image.nil?
    return self.image       if self.image.is_a? ImageUploader::UploadedFile
    return self.image[size] if self.image.is_a? Hash
    nil
  end

  def thumbnail_image(size=:small)
    return self.thumb(size).try(:url)
  end
  
  def create_schedule(data)
    new_sched = ClassdefSchedule.create(data)
    add_schedule(new_sched)
    new_sched
  end

  def all_reservations
    query = %{
      SELECT * FROM class_occurrences
      JOIN class_reservations
      ON class_occurrences.id = class_reservations.class_occurrence_id
      WHERE class_occurrences.classdef_id = ?
    }
    $DB[query, self.id].all
  end

  def frequent_flyers
    all_reservations.map do |res| 
      Customer[res[:customer_id]].try(:to_list_hash)
    end.group_by(&:itself).map do |k,v| 
      [k, v.size]
    end.map do |k,v| 
      k.nil? ? { :count=>v } : { :count=>v }.merge(k)
    end.sort_by do |x|
      -x[:count]
    end.first(20)
  end

  ####################### OCCURRENCES ############################
 
  def get_occurrences(from, to)
    schedules.map { |s| s.get_occurrences(from,to) }.flatten
  end

  def get_occurrences_with_exceptions(from, to)
    schedules.map { |s| s.get_occurrences_with_exceptions(from,to) }.flatten
  end

  def get_occurrences_with_exceptions_merged(from,to)
    schedules.map { |s| s.get_occurrences_with_exceptions_merged(from,to) }.flatten
  end

  def get_full_occurrences(from, to)
    schedules.map do |sched|
      sched.get_occurrences(from,to).map do |x|
        exception = ClassException.find( :classdef_id => self.id, :original_starttime => x.start_time.iso8601 )
        #next if exception.cancelled unless exception.nil?
        teachers = ( exception.nil? ? sched.teachers : exception[:teacher_id].nil? ? sched.teachers : [ Staff[exception[:teacher_id]] ] )
        { :teachers => teachers.map { |x| { :id => x[:id], :name => x[:name], :image_url => x.image_url(:small) } }, 
          :starttime => x.start_time.iso8601, 
          :exception => exception 
        }
      end
    end.flatten.compact.sort_by { |x| x[:starttime] }
  end

  def get_final_occurrences(from, to)
    schedules.map do |sched|
      sched.get_occurrences_with_exceptions_merged(from,to)
    end.flatten.compact.sort_by { |x| x[:starttime] }
  end

  def get_next_occurrences(num)
    num = Integer(num)
    results = []
    period_start = Time.now
    while results.length < num
      next_week = get_final_occurrences(period_start, period_start + (60*60*24*7) )
      next if next_week.nil?
      next if results.nil?
      while results.length < num && next_week.length > 0 
        results << next_week.shift
      end
      period_start = period_start + (60*60*24*7)
      break if period_start > ( Time.now + (3600*24*7*8) )
    end
    results
  end

  ######################### OCCURRENCES ##########################

  ########################### VIEWS ##############################

  def poster_lines; footer_lines end
  def footer_lines
    lines = [self.name]
    self.meeting_times.each_slice(2) { |a,b| lines << ( b.nil? ? a : a +", " + b ) }
    lines
  end

  def footer_lines_teachers
    lines = [self.name]
    self.meeting_times_with_staff.each { |a| lines << a }
    lines
  end

  def to_json(options = {})
    val = JSON.parse super
    val['image_url'] = image.nil? ? '' : image(:original).nil? ? image.url : image(:original).url
    val['image_data'] = JSON.parse(val['image_data']||"{}")
    JSON.generate val
  end

  def to_token
    { :id => id, :name => name }
  end

  def classpage_view
    { :id => self.id, 
      :name => self.name, 
      :image_url => self.thumbnail_image,
      :locations => self.schedules.map(&:location).uniq
    }
  end

  def adminpage_view
    classpage_view.merge({
      :description => self.description,
      :schedules   => self.schedules
    })
  end

  def meeting_times
    self.schedules.map(&:simple_meeting_time_description)
  end

  def meeting_times_with_staff
    self.ordered_schedules.map(&:simple_meeting_time_description_with_staff)
  end

  ########################## VIEWS ##############################

  def ordered_schedules
    self.schedules.sort_by { |x| x.next_occurrence(Date.parse("Monday").to_time) }
  end

end

