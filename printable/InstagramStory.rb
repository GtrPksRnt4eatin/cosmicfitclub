require 'date'
require 'mini_magick'

module InstagramStory

  def InstagramStory::set_constants
    @@lines_xmargin       = 0
    @@lines_bottom_margin = 200
    @@lines_pointsize1    = 125
    @@lines_pointsize2    = 110
    @@footer_pointsize    = 19
    @@lineheight          = 142
  end
 
  def InstagramStory::generate(event_id, lines, path)

    InstagramStory::set_constants

    @@lines = lines
    @@image ||= MiniMagick::Image.open "printable/assets/1080x1920_bg.jpg"

    @@bubble = MiniMagick::Image.open "printable/assets/#{event_id}"        if event_id.is_a? String
    @@bubble = MiniMagick::Image.open Event[event_id].image(:original).url  if event_id.is_a? Integer
    @@bubble.to_bubble(lines)

    @@image.draw_logo(60,210,960,nil)

    @@image.bubble_shadow(980,980,50,585,5)
    @@image.overlay(@@bubble,980,980,50,585)

    @@image.draw_highlight_text("cosmicfitclub.com#{path}",19,0,240,"south","\#CC0000FF")

    @@image.draw_footer(8,170)

    @@image

  end

end