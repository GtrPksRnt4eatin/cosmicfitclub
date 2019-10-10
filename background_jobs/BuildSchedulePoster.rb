require 'sucker_punch'

class BuildSchedulePoster
  include SuckerPunch::Job

  def perform(starttime)
    blob = SchedulePoster::generate(starttime)
    img  = StoredImage.create( :image => blob, :name => "WeeklyPoster.jpg" )
    puts img
    puts img.image[:original].url
  end

end