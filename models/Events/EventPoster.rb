require 'date'
require 'mini_magick'

module EventPoster
 
  def EventPoster::generate(event_id, lines)

    p "Generating Event Poster"
    @@lines = lines
    @@event = Event[event_id]
    @@image = MiniMagick::Image.open @@event.image[:original].url

    EventPoster::draw_box(0,1000,2550,550,0,0)
    EventPoster::render_footer

    p "Finished Generating Event Poster"
    @@image

  end

  ################################### RENDERING ######################################

  def EventPoster::draw_box(x_offset, y_offset, x, y, x_radius=25, y_radius=25 )
    @@image.combine_options do |i|
      i.fill "\#FF000099"
      i.draw "roundRectangle #{x_offset},#{y_offset} #{x_offset + x},#{y_offset + y} #{x_radius},#{y_radius}"
    end
  end

  def EventPoster::render_footer
    @@image.combine_options do |i|
      i.font "shared/fonts/webfonts/329F99_3_0.ttf"
      i.pointsize 22
      i.fill "\#FFFFFFFF"
      i.gravity "south"
      i.draw "text 0,0 \"#{@@lines.join("\r\n")}\""
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