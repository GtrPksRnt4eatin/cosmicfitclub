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
 
  def InstagramStory::generate(event_id, lines)

    InstagramStory::set_constants

    @@lines = lines
    @@image ||= MiniMagick::Image.open "printable/assets/1080x1920_bg.jpg"

    @@bubble = MiniMagick::Image.open "printable/assets/#{event_id}"        if event_id.is_a? String
    @@bubble = MiniMagick::Image.open Event[event_id].image[:original].url if event_id.is_a? Integer
    @@bubble.to_bubble(lines)

    @@image.draw_logo(60,210,960,nil)

    @@image.bubble_shadow(980,980,50,585,5)
    @@image.overlay(@@bubble,980,980,50,585)

    @@image.draw_highlight_text("cosmicfitclub.com/unity",21,0,240,"south","\#CC0000FF")

    @@image.draw_footer(8,170)

    @@image

  end

  ################################### RENDERING ######################################

  def InstagramStory::draw_lines
    @@image.combine_options do |i|
      i.fill "\#FFFFFFFF"
      i.gravity "south"
      @@lines.each_with_index do |line,idx|
        i.font "shared/fonts/webfonts/329F99_3_0.ttf" if idx==0
        i.pointsize 125                               if idx==0
        i.font "shared/fonts/webfonts/329F99_B_0.ttf" unless idx==0
        i.pointsize 110                               unless idx==0
        i.draw "text 0,#{( @@lines_bottom_margin + @@lineheight * 0.5 + (@@lines.count - idx - 1) * 142 )} \"#{line}\""
      end
    end
  end

  ################################### RENDERING ######################################

  ################################### ELEMENTS #######################################

  def InstagramStory::draw_box(x_offset, y_offset, x, y, x_radius=25, y_radius=25 )
    @@image.combine_options do |i|
      i.fill "\#00000099"
      i.draw "roundRectangle #{x_offset},#{y_offset} #{x_offset + x},#{y_offset + y} #{x_radius},#{y_radius}"
    end
  end

  ################################### ELEMENTS #######################################

  #################################### HELPERS #######################################

  def InstagramStory::truncate(string,max)
    return "" if string.nil?
    string.length > max ? "#{string[0...max]}..." : string
  end

  #################################### HELPERS #######################################

end