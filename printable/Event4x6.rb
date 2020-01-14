require 'date'
require 'mini_magick'

module Event4x6
 
  def Event4x6::generate(event_id)

    @@image = MiniMagick::Image.open('printable/assets/4x6_bg.jpg')
    
    @@image.draw_logo(50,50,1100)
    @@image.draw_event_bubble(event_id,50,550,1100)    
    @@image.draw_footer

  end

end