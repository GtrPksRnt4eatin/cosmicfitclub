class Time
  def to_json(*args)
  	"\"#{iso8601}\""
  end

  def to_classtime(*args)
    strftime("%a %b #{self.day.ordinalize} @ %l:%M%P")
  end
end

class Array
  def to_json(options = {})
    JSON.generate(self)
  end
end

class Hash
  def to_json(options = {})
    JSON.generate(self)
  end
end

class Integer
  def fmt_stripe_money
    "$ #{ ( self.to_f / 100 ).round(2) }"
  end
end