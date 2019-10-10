require 'sucker_punch'

class BuildSchedulePoster
  include SuckerPunch::Job

  def perform(starttime)
  	p "starting background job"
    img = SchedulePoster::generate(starttime)
    img = StoredImage.find( :name => "WeeklyPoster.jpg" )
    if img.nil? then
      img = StoredImage.create( :name => "WeeklyPoster.jpg", :image=> File.open(img.path) )
    else
      img = img.update( :image=> File.open(img.path), :saved_on=>DateTime.now )
    end
    p "finished background job"
  end

end