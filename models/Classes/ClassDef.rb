require 'ice_cube'
require 'active_support/core_ext/numeric/time.rb'

class ClassDef < Sequel::Model

  one_to_many :schedules, :class => :ClassdefSchedule, :key => :classdef_id 
  one_to_many :occurrences, :class => :ClassOccurrence, :key => :classdef_id

  include ImageUploader[:image]

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

  def deactivate
    self.update( :deactivated => true )
  end

end