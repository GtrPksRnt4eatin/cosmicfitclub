require 'sucker_punch'

class BuildSchedulePoster
  include SuckerPunch::Job

  def perform(starttime)
  	p "starting background job"
    blob = SchedulePoster::generate(starttime)
    p blob
    img  = StoredImage.create( :image => blob, :name => "WeeklyPoster.jpg" )
    puts img
    puts img.image[:original].url
  end

end