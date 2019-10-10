require 'sucker_punch'

class BuildSchedulePoster
  include SuckerPunch::Job

  def perform(starttime)
  	p "starting background job"
    img   = SchedulePoster::generate(starttime)
    store = StoredImage.find( :name => "WeeklyPoster.jpg" )
    if store.nil? then
      store = StoredImage.create( :name => "WeeklyPoster.jpg", :image=> File.open(img.path) )
    else
      store = img.update( :image=> File.open(img.path), :saved_on=>DateTime.now )
    end
    p "finished background job"
  end

end