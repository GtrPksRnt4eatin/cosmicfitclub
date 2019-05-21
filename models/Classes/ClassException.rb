class ClassException < Sequel::Model

  many_to_one :teacher, :key => :teacher_id, :class => :Staff
  many_to_one :classdef
  
  def ClassException.between(from,to)
    self.order_by(:starttime).map do |ex|
      next if ex.starttime.nil?
      start = Time.parse(ex.starttime)
      next if start < from
      next if start >= to
      ex
    end.compact!
  end

  def type
    return 'cancellation' if self.cancelled
    return 'time_change'  unless self.starttime.nil?
    return 'substitute'   unless self.teacher_id.nil?
    return nil
  end

  def details
    { :id => self.id,
      :classdef_id => self.classdef_id,
      :classdef_name => self.classdef.name,
      :teacher_id => self.teacher_id,
      :teacher_name => self.teacher.try(:name),
      :starttime => self.starttime,
      :original_starttime => self.original_starttime,
      :cancelled => self.cancelled,
      :hidden => self.hidden,
      :type => self.type
    }
  end
  
end