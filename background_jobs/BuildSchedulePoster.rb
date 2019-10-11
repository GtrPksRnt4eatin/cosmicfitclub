require 'sucker_punch'

class BuildSchedulePoster
  include SuckerPunch::Job

  def perform(starttime=Date.today)
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
  	img = img.composite(img) do |c|
      c.gravity "NorthWest"
      c.geometry '1225x1650+0+0' 
  	end

  	img = img.composite(img) do |c|
      c.gravity "NorthEast"
      c.geometry '1225x1650+0+0' 
  	end

  	img = img.composite(img) do |c|
      c.gravity "SouthWest"
      c.geometry '1225x1650+0+0' 
  	end

  	img = img.composite(img) do |c|
      c.gravity "SouthEast"
      c.geometry '1225x1650+0+0' 
  	end

  	store = StoredImage.find( :name => "WeeklyPosterQuad.jpg" )
    if store.nil? then
      store = StoredImage.create( :name => "WeeklyPosterQuad.jpg", :image=> File.open(img.path) )
    else
      store = store.update( :image=> File.open(img.path), :saved_on=>DateTime.now )
    end

  	#images = [path,path,path,path]
    #processed_image = MiniMagick::Tool::Montage.new do |image|
    #  #2550x3300
    #  image.geometry "x1225+0+0"
    #  image.tile "#{images.size}x1"
    ##  images.each {|i| image << i}
    #  image << "output.jpg"
    #end

  end

end