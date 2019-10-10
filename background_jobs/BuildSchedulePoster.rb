require 'sucker_punch'

class BuildSchedulePoster
  include SuckerPunch::Job

  def perform(starttime)
  	p "starting background job"
    img = SchedulePoster::generate(starttime)
    img.path
    StoredImage.create( :image => File.open(img.path), :name => "WeeklyPoster.jpg" )
  end

end