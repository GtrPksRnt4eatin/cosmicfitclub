require 'sucker_punch'

class BuildSchedulePoster
  include SuckerPunch::Job

  def perform(starttime)
  	p "starting background job"
    blob = SchedulePoster::generate(starttime)
    p blob
    rd, wr = IO.pipe
    blob.write(rd)
    img  = StoredImage.create( :image => wr, :name => "WeeklyPoster.jpg" )

    puts img
    puts img.image[:original].url
  end

end