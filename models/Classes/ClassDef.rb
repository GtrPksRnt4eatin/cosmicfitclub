require 'ice_cube'
require 'active_support/core_ext/numeric/time.rb'

class ClassDef < Sequel::Model
  include PositionAndDeactivate

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

  def create_schedule(data)
    new_sched = ClassdefSchedule.create(data)
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
      sched.get_occurrences(from,to).map do |x|
        exception = ClassException.find( :classdef_id => self.id, :original_starttime => x.start_time.iso8601 )
        teachers = ( exception.nil? ? sched.teachers : exception[:teacher_id].nil? ? sched.teachers : [ Staff[exception[:teacher_id]] ] )
        { :teachers => teachers.map { |x| { :id => x[:id], :name => x[:name], :image_url => x.image_url(:small) } }, 
          :starttime => x.start_time.iso8601, 
          :exception => exception 
        }
      end
    end.flatten.sort_by { |x| x[:starttime] }
  end

  def to_listitem
    { :id => id, :name => name }
  end

end
