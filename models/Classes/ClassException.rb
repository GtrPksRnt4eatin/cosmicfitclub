class ClassException < Sequel::Model
  
  def ClassException.between(from,to)
    self.order_by(:starttime).map do |ex|
      next if ex.starttime.nil?
      start = Time.parse(ex.starttime)
      next if start < from
      next if start >= to
      ex
    end.compact!
  end

end