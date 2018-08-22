class Time
  def to_json(*args)
  	"\"#{iso8601}\""
  end

  def to_classtime(*args)
    strftime("%a %b #{self.day.ordinalize} @ %l:%M%P")
  end
end