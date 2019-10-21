require 'sucker_punch'

class BuildEventPoster
  include SuckerPunch::Job

  def perform(event_id, lines)
  	event = Event[event_id]
    img = EventPoster::generate(event_id, lines)
    store = StoredImage.find( :name => "EventPoster_#{event.id}.jpg" )
     if store.nil? then
      store = StoredImage.create( :name => "EventPoster_#{event.id}.jpg", :image=> File.open(img.path) )
    else
      store = store.update( :image=> File.open(img.path), :saved_on=>DateTime.now )
    end
  end

end