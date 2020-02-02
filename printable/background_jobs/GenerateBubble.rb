require 'sucker_punch'

class GenerateBubble
  include SuckerPunch::Job

  def perform(img_path, lines, opts)
    @@image = MiniMagick::Image.open img_path

    @@image.to_bubble(lines, opts[:ptscale] || 0.05, opts[:ptscale2] || 0.74 )

    yield @@image if block_given?

  	#img = GiftCert::generate_tall(self.id)
   #      img = File.open( img.path )
   #     img = StoredImage.create( :name => "GiftCert[#{self.id}]_tallimg.jpg", :image => img )
   #      self.update( :tall_image => img )

  	#event = Event[event_id]
    #img = EventPoster::generate(event_id, lines)
    #store = StoredImage.find( :name => "EventPoster_#{event.id}.jpg" )
    # if store.nil? then
    #  store = StoredImage.create( :name => "EventPoster_#{event.id}.jpg", :image=> File.open(img.path) )
    #else
    #  store = store.update( :image=> File.open(img.path), :saved_on=>DateTime.now )
    #end
  end

end