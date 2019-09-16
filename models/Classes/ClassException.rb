class ClassException < Sequel::Model

  many_to_one :teacher,  :key => :teacher_id,  :class => :Staff
  many_to_one :classdef, :key => :classdef_id, :class => :ClassDef

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
    return 'substitute'   unless self.teacher_id.nil?
    return 'rescheduled'  unless self.starttime.nil?
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

  def full_details
    { :id          => self.id,
      :classdef    => self.classdef.to_token,
      :starttime   => self.original_starttime,
      :description => self.description,
      :type        => self.type,
      :changes     => {
        :sub         => self.teacher.try(:to_token),
        :starttime   => self.starttime,
        :cancelled   => self.cancelled,
        :hidden      => self.hidden,
      }  
    }
  end

  def time_12h(val) 
    Time.parse(val.to_s).strftime("%Y %b %-d @ %I:%M %P") rescue val 
  end

  def description
    str = "#{self.classdef.name} on #{time_12h(self.original_starttime)} "
    str << "Was Cancelled"                                  if self.type == 'cancellation'
    str << "Will Be Subbed By #{self.teacher.name}"         if self.type == 'substitute'
    str << "Was Rescheduled to #{time_12h(self.starttime)}" if self.type == 'rescheduled'
    return str
  end
  
end