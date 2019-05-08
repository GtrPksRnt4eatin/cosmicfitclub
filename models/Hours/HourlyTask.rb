class HourlyTask < Sequel::Model

  one_to_many :hourly_shifts

  def to_token
  	{ :id => self.id, :name => self.name }
  end

end