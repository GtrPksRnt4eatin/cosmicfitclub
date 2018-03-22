module PositionAndDeactivate
  def move(up)

    pos  = position
    other = self.class.where{ position < pos }.exclude(:deactivated).order(:position).last  if up
    other = self.class.where{ position > pos }.exclude(:deactivated).order(:position).first unless up
    self.update( :position => other.position )
    other.update( :position => pos )
  end

  def deactivate
    self.update( :deactivated => true )
  end
end