class BuildSchedulePoster
  include SuckerPunch::Job

  def perform(starttime)
    blob = SchedulePoster::generate(starttime)
    StoredImage.create( :image => blob, :name => "WeeklyPoster_#{starttime.to_s}.jpg" )
  end

end