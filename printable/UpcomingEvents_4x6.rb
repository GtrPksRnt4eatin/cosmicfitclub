require 'date'
require 'mini_magick'

module Upcoming_Events_4x6
 
  def Upcoming_Events_4x6::generate(event_ids)

    @@image = MiniMagick::Image.open('printable/assets/4x6_bg.jpg')
    
    @@image.draw_logo(50,50,1100)
    @@image.draw_box(50,465,1100,100,30,30)
    @@image.draw_text_header('Upcoming Events!',16,0,485,'North')
    @@image.draw_event_bubble(event_ids[0],50,600,525)
    @@image.draw_event_bubble(event_ids[1],625,600,525) 
    @@image.draw_event_bubble(event_ids[2],338,1175,525) 
    @@image.draw_footer

  end

end