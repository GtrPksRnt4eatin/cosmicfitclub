require 'date'
require 'mini_magick'

module SchedulePoster4x6_class
 
  def SchedulePoster4x6_class::generate(classdef_id,img,lines)

    @@image = MiniMagick::Image.open("printable/assets/4x6_bg.jpg") # 1130x1730
    
    @@image.draw_logo(75,50,1050,nil)

    @@image.draw_iphone_bubble2(classdef_id, 75, 460, 1050, 1050*1.1) if classdef_id

    @@bubble = MiniMagick::Image.open(ClassDef[classdef_id].image[:original].url) if classdef_id
    @@bubble = MiniMagick::Image.open("printable/assets/#{img}")              unless classdef_id
    
    @@image.draw_highlight_text("First Class Free! Come In Today!",18,0,75,"South")

    @@image.draw_footer(9)

  end
  
end