class ClassException < Sequel::Model

  many_to_one :teacher, :key => :teacher_id, :class => :Staff
  
  def ClassException.between(from,to)
    self.order_by(:starttime).map do |ex|
      next if ex.starttime.nil?
      start = Time.parse(ex.starttime)
      next if start < from
      next if start >= to
      ex
    end.compact!
  end

  def details
    { :id => self.id,
      :classdef_id => self.classdef_id,
      :teacher_id => self.teacher_id,
      :teacher_name => self.teacher.try(:name),
      :starttime => self.starttime,
      :original_starttime => self.original_starttime,
      :cancelled => self.cancelled,
      :hidden => self.hidden
    }
  end
  
end