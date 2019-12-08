require 'date'
require 'mini_magick'

module EventPoster2
 
  def EventPoster2::generate(event_id, lines)

    @@lines = lines
    @@event = Event[event_id]
    @@image = MiniMagick::Image.open("printable/assets/1080x1080_bg.jpg")

    @@bubble = MiniMagick::Image.open @@event.image[:original].url
    @@bubble.resize "980x980!"
    @@bubble.to_bubble(lines)

    @@image.bubble_shadow(1040,1040,20,20,2)
    @@image.overlay(@@bubble,1040,1040,20,20)
    #@@image.draw_footer(9)

    @@image

  end

  ################################### RENDERING ######################################

  def EventPoster2::draw_box(x_offset, y_offset, x, y, x_radius=25, y_radius=25 )
    @@image.combine_options do |i|
      i.fill "\#00000099"
      i.draw "roundRectangle #{x_offset},#{y_offset} #{x_offset + x},#{y_offset + y} #{x_radius},#{y_radius}"
    end
  end

  def EventPoster2::render_footer
    @@image.combine_options do |i|
      i.fill "\#FFFFFFFF"
      i.gravity "south"
      @@lines.each_with_index do |line,idx|
        i.font "shared/fonts/webfonts/329F99_3_0.ttf" if idx==0
        i.pointsize 125                               if idx==0
        i.font "shared/fonts/webfonts/329F99_B_0.ttf" unless idx==0
        i.pointsize 110                               unless idx==0
        i.draw "text 0,#{( 50 + (@@lines.count - idx - 1) * 142 )} \"#{line}\""
      end
    end
  end


  ################################### RENDERING ######################################

  #################################### HELPERS #######################################

  def EventPoster2::truncate(string,max)
    return "" if string.nil?
    string.length > max ? "#{string[0...max]}..." : string
  end

  #################################### HELPERS #######################################

end