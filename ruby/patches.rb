class Time
  def to_json(*args)
  	"\"#{iso8601}\""
  end
end