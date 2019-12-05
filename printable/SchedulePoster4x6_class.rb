require 'date'
require 'mini_magick'

module SchedulePoster4x6_class
 
  def SchedulePoster4x6_class::generate(img,lines)

    @@image = MiniMagick::Image.open("printable/assets/4x6_bg.jpg") # 1130x1730
    
    @@image.draw_logo(75,50,1050,nil)

    #@@image.draw_iphone_bubble2(classdef_id, 75, 460, 1050, 1050*1.1)

    @@bubble = MiniMagick::Image.open("printable/assets/#{img}")
    @@bubble.to_bubble(lines)

    margin = 1050*0.005          # Border Around Image
    @@image.draw_box(75-margin, 460-margin, 1050+margin*2, 1050*1.1+margin*2, 1050/10, 1050*1.1/10, 'None', "\#FFFFFF66")
    
    @@image.overlay(@@bubble,1050,1050*1.1,75,460)

    @@image.draw_highlight_text("First Class Free! Come In Today!",18,0,75,"South")

    @@image.draw_footer(9)

  end
  
end