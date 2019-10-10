require 'suckerpunch'

class BuildSchedulePoster
  include SuckerPunch::Job

  def perform(starttime)
    blob = SchedulePoster::generate(starttime)
    StoredImage.create( :image => blob, :name => "WeeklyPoster.jpg" )
  end

end