require 'date'
require 'mini_magick'

module EventPoster
 
  def EventPoster::generate(event_id, lines)

    p "Generating Event Poster"
    @@lines = lines
    @@event = Event[event_id]
    @@image = MiniMagick::Image.open @@event.image[:original].url
    @@image.resize "2550x2550!"

    box_start = 2550 - ( lines.count * 142 ) - 100  
    EventPoster::draw_box(0,box_start,2550,2550,0,0) unless @@lines.count == 0
    EventPoster::render_footer

    p "Finished Generating Event Poster"
    @@image

  end

  ################################### RENDERING ######################################

  def EventPoster::draw_box(x_offset, y_offset, x, y, x_radius=25, y_radius=25 )
    @@image.combine_options do |i|
      i.fill "\#00000099"
      i.draw "roundRectangle #{x_offset},#{y_offset} #{x_offset + x},#{y_offset + y} #{x_radius},#{y_radius}"
    end
  end

  def EventPoster::render_footer
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

  def EventPoster::truncate(string,max)
    return "" if string.nil?
    string.length > max ? "#{string[0...max]}..." : string
  end

  #################################### HELPERS #######################################

end