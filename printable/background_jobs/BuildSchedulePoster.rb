require 'sucker_punch'

class BuildSchedulePoster
  include SuckerPunch::Job

  def perform(starttime=Date.tomorrow)
  	p "starting background job"
    img   = SchedulePoster::generate(starttime)
    store = StoredImage.find( :name => "WeeklyPoster.jpg" )
    if store.nil? then
      store = StoredImage.create( :name => "WeeklyPoster.jpg", :image=> File.open(img.path) )
    else
      store = store.update( :image=> File.open(img.path), :saved_on=>DateTime.now )
    end
    build_quad_poster(img)
    p "finished background job"
  end

  def build_quad_poster(img)
  	image = img.composite(img) do |c|
      c.gravity "NorthWest"
      c.geometry '1275x1650+0+0' 
  	end

  	image = image.composite(img) do |c|
      c.gravity "NorthEast"
      c.geometry '1275x1650+0+0' 
  	end

  	image = image.composite(img) do |c|
      c.gravity "SouthWest"
      c.geometry '1275x1650+0+0' 
  	end

  	image = image.composite(img) do |c|
      c.gravity "SouthEast"
      c.geometry '1275x1650+0+0' 
  	end

  	store = StoredImage.find( :name => "WeeklyPosterQuad.jpg" )
    if store.nil? then
      store = StoredImage.create( :name => "WeeklyPosterQuad.jpg", :image=> File.open(image.path) )
    else
      store = store.update( :image=> File.open(image.path), :saved_on=>DateTime.now )
    end

  end

end