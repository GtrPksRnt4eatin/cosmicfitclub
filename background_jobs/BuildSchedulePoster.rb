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
    build_quad_poster(img.path)
    p "finished background job"
  end

  def build_quad_poster(path)
  	images = [path,path,path,path]
    processed_image = MiniMagick::Tool::Montage.new do |image|
      #2550x3300
      image.geometry "x1225+0+0"
      image.tile "#{images.size}x1"
      images.each {|i| image << i}
      image << "output.jpg"
    end
    p processed_image
  end

end