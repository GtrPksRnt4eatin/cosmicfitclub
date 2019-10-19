require 'date'
require 'mini_magick'

module SchedulePoster
 
  def SchedulePoster::set_class_vars
    @@line_height      = 60
    @@header_pointsize = 55
    @@body_pointsize   = 42
    @@box_width        = 2450
  end
 
  def SchedulePoster::generate(starttime, high_contrast=false)

  	SchedulePoster::set_class_vars

  	@@high_contrast = high_contrast
    p "Getting Schedule #{Time.now}"
    @@schedule      = Scheduling::get_all_sorted_by_days(starttime, starttime >> 7)
    @@image         = MiniMagick::Image.open("shared/img/background-blu.jpg") unless @@high_contrast
    @@image         = MiniMagick::Image.open("./white.png")                          if @@high_contrast
    @@image.rotate "90"
    @@image.resize "2550x3300!"
    
    offset = SchedulePoster::build_day(0,50,150)
    offset = SchedulePoster::build_day(1,50,offset + 25)
    offset = SchedulePoster::build_day(2,50,offset + 25)
    offset = SchedulePoster::build_day(3,50,offset + 25)
    offset = SchedulePoster::build_day(4,50,offset + 25)
    offset = SchedulePoster::build_day(5,50,offset + 25)
    offset = SchedulePoster::build_day(6,50,offset + 25)

    @@image

  end

  ################################### RENDERING ######################################

  def SchedulePoster::build_day(idx, x_offset, y_offset)
    p "Building Day #{idx} #{Time.now}"  
    day = @@schedule[idx]
    box_height = (@@line_height * 1.7) + ( @@line_height * day[:occurrences].count )
    SchedulePoster::draw_box(x_offset, y_offset, @@box_width, box_height ) unless @@high_contrast
    x_offset = x_offset + 20
    y_offset = y_offset + (@@line_height * 1.1)
    SchedulePoster::render_header_line(day, x_offset, y_offset)
    y_offset = y_offset + ( @@line_height * 0.1 )
    day[:occurrences].each do |occ|
      y_offset = y_offset + @@line_height
      SchedulePoster::render_text_line(occ, x_offset, y_offset)
    end
    y_offset = y_offset + @@line_height*0.5
    return y_offset
  end

  def SchedulePoster::draw_box(x_offset, y_offset, x, y, x_radius=25, y_radius=25 )
    @@image.combine_options do |i|
      i.fill "\#00000099"
      i.draw "roundRectangle #{x_offset},#{y_offset} #{x_offset + x},#{y_offset + y} #{x_radius},#{y_radius}"
    end
  end

  def SchedulePoster::render_header_line(day, x_offset, y_offset)
    @@image.combine_options do |i|
      i.fill "\#FFFFFFFF" unless @@high_contrast
      i.fill "\#000000FF"     if @@high_contrast
      i.font "shared/fonts/webfonts/329F99_3_0.ttf"
      i.pointsize @@header_pointsize
      i.draw "text #{x_offset},#{y_offset} \"#{SchedulePoster::parse_day(day[:day])}\""
    end
  end

  def SchedulePoster::render_text_line(occ, x_offset, y_offset) 
    col1_x, col2_x, col3_x = 75, 600, 1750
    col2_trunc, col3_trunc = 53, 28

    @@image.combine_options do |i|
      i.pointsize @@body_pointsize
      i.font "shared/fonts/webfonts/329F99_3_0.ttf"
      case occ[:type]
      when 'classoccurrence'
        teachers = occ[:instructors] ? occ[:instructors][0][:name] : ""
        i.fill "\#FFFFFFFF" unless @@high_contrast
        i.fill "\#000000FF"     if @@high_contrast
        i.draw "text #{x_offset + col1_x },#{y_offset} \"#{SchedulePoster::parse_time(occ)}\""
        i.draw "text #{x_offset + col2_x },#{y_offset} \"#{SchedulePoster::truncate(occ[:title],col2_trunc)}\""
        i.draw "text #{x_offset + col3_x },#{y_offset} \"w/ #{SchedulePoster::truncate(teachers,col3_trunc)}\""
      when 'eventsession'
        i.fill "\#FFFFAAFF" unless @@high_contrast
        i.fill "\#999900FF"     if @@high_contrast
        i.draw "text #{x_offset + col1_x },#{y_offset} \"#{SchedulePoster::parse_time(occ)}\""
        i.draw "text #{x_offset + col2_x },#{y_offset} \"#{SchedulePoster::truncate(occ[:event_title],col2_trunc)}\""
        i.draw "text #{x_offset + col3_x },#{y_offset} \"#{SchedulePoster::truncate(occ[:title],col3_trunc)}\""
      when 'private' then
        i.fill "\#AAAAFFFF" unless @@high_contrast
        i.fill "\#000099FF"     if @@high_contrast
        i.draw "text #{x_offset + col1_x },#{y_offset} \"#{SchedulePoster::parse_time(occ)}\""
        i.draw "text #{x_offset + col2_x },#{y_offset} \"#{SchedulePoster::truncate(occ[:title],col2_trunc)}\""
      end
    end
  end

  ################################### RENDERING ######################################

  #################################### HELPERS #######################################

  def SchedulePoster::truncate(string,max)
    return "" if string.nil?
    string.length > max ? "#{string[0...max]}..." : string
  end

  def SchedulePoster::parse_day(str)
    dt = DateTime.parse(str)
    dt.strftime("%a %b %e")
  end 

  def SchedulePoster::parse_time(occ)
    start   = occ[:starttime]
    finish  = occ[:endtime]
    start.strftime("%l:%M %P - ") + finish.strftime("%l:%M %P")
  end

  #################################### HELPERS #######################################

end