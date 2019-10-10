require 'sucker_punch'

class BuildSchedulePoster
  include SuckerPunch::Job

  def perform(starttime)
  	p "starting background job"
    img = SchedulePoster::generate(starttime)
    img = StoredImage.find_or_create( :name => "WeeklyPoster.jpg" )
    img.update( :image=> File.open(img.path)  )
    p "finished background job"
  end

end