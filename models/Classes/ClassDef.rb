require 'ice_cube'
require 'active_support/core_ext/numeric/time.rb'

class ClassDef < Sequel::Model

  one_to_many :schedules, :class => :ClassdefSchedule, :key => :classdef_id 
  one_to_many :occurrences, :class => :ClassOccurrence, :key => :classdef_id

  include ImageUploader[:image]

  def ClassDef.all_active
    ClassDef.exclude(:deactivated=>true).order(:position).all.select! { |x| x.schedules.count > 0 }
  end

  def after_save
  	self.id
  	super
  end 

  def to_json(options = {})
    val = JSON.parse super
    val['image_url'] = image.nil? ? '' : image[:original].url
    JSON.generate val
  end

  def create_schedule
    new_sched = ClassdefSchedule.create
    add_schedule(new_sched)
    new_sched
  end

  def get_occurences(from, to)
    schedules.map do |sched|
      sched.get_occurences(from,to)
    end.flatten
  end

  def get_full_occurences(from, to)
    schedules.map do |sched|
      sched.get_occurences(from,to).map { |x| { :teachers => sched.teachers, :starttime => x.start_time, :exception => ClassException.find( :classdef_id => self.id, :original_starttime => x.start_time.iso8601 ) } }
    end.flatten
  end

  def move(up)
    thispos  = position
    otherpos = ClassDef.where("position < #{self.position}").reverse_order(:position).first if up
    otherpos = ClassDef.where("position > #{self.position}").order(:position).first         unless up
    self.update( :position => prev.position )
    prev.update( :position => pos )
  end

  def deactivate
    self.update( :deactivated => true )
  end

end