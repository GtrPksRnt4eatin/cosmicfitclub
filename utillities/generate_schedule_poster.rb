require_relative './db_models'
require 'date'
require 'mini_magick'

items = Scheduling::get_all_between(Time.parse("2019-10-08"),Time.parse("2019-10-15"))
arr = []
items.each { |k,v| arr << { :day => k, :occurrences => v.sort_by { |x| x[:starttime] } } }

SCHEDULE = arr.sort_by { |x| x[:day] }

HIGH_CONTRAST = false

IMAGE    = MiniMagick::Image.open("../shared/img/background-blu.jpg") unless HIGH_CONTRAST
IMAGE    = MiniMagick::Image.open("./white.png")                          if HIGH_CONTRAST

LINE_HEIGHT = 60


def truncate(string,max)
  return "" if string.nil?
  string.length > max ? "#{string[0...max]}..." : string
end

def parse_day(str)
  dt = DateTime.parse(str)
  dt.strftime("%a %b %e")
end

def parse_time(occ)
  start   = occ[:starttime]
  finish  = occ[:endtime]
  start.strftime("%l:%M %P - ") + finish.strftime("%l:%M %P")
end

def draw_box_raw(x_offset,y_offset,x,y)
  IMAGE.combine_options do |i|
    i.fill "\#00000099"
    i.draw "roundRectangle #{x_offset},#{y_offset} #{x_offset + x},#{y_offset + y} 25,25"
  end
end

def draw_box(x_offset,y_offset)
  draw_box_raw(x_offset,y_offset,2250,350)
end

def render_header_line(idx, x_offset, y_offset)
  IMAGE.combine_options do |i|
    i.fill "\#FFFFFFFF" unless HIGH_CONTRAST
    i.fill "\#000000FF"     if HIGH_CONTRAST
    i.font "../shared/fonts/webfonts/329F99_3_0.ttf"
    i.pointsize 55
    i.draw "text #{x_offset},#{y_offset} '#{parse_day(SCHEDULE[idx][:day])}'"
  end
end

def render_text_line(image, occ, x_offset, y_offset)
  col1_x, col2_x, col3_x = 75, 600, 1750
  col2_trunc, col3_trunc = 53, 28

  IMAGE.combine_options do |i|
    i.pointsize 42
    i.font "../shared/fonts/webfonts/329F99_3_0.ttf"
    case occ[:type]
    when 'classoccurrence'
      teachers = occ[:instructors] ? occ[:instructors][0][:name] : ""
      i.fill "\#FFFFFFFF" unless HIGH_CONTRAST
      i.fill "\#000000FF"     if HIGH_CONTRAST
      i.draw "text #{x_offset + col1_x },#{y_offset} '#{parse_time(occ)}'"
      i.draw "text #{x_offset + col2_x },#{y_offset} '#{truncate(occ[:title],col2_trunc)}'"
      i.draw "text #{x_offset + col3_x },#{y_offset} 'w/ #{truncate(teachers,col3_trunc)}'"
    when 'eventsession'
      i.fill "\#FFFFAAFF" unless HIGH_CONTRAST
      i.fill "\#999900FF"     if HIGH_CONTRAST
      i.draw "text #{x_offset + col1_x },#{y_offset} '#{parse_time(occ)}'"
      i.draw "text #{x_offset + col2_x },#{y_offset} '#{truncate(occ[:event_title],col2_trunc)}'"
      i.draw "text #{x_offset + col3_x },#{y_offset} '#{truncate(occ[:title],col3_trunc)}'"
    when 'private' then
      i.fill "\#AAAAFFFF" unless HIGH_CONTRAST
      i.fill "\#000099FF"     if HIGH_CONTRAST
      i.draw "text #{x_offset + 75 },#{y_offset} '#{parse_time(occ)}'"
      i.draw "text #{x_offset + 600 },#{y_offset} \"#{truncate(occ[:title],53)}\""
    end
  end
end

def build_day(idx, x_offset, y_offset)
  line_height = 60
  box_width = 2450
  box_height = (line_height * 0.7) + ( line_height * SCHEDULE[idx][:occurrences].count ) + line_height
  draw_box_raw(x_offset, y_offset, box_width, box_height ) unless HIGH_CONTRAST
  x_offset = x_offset + 20
  y_offset = y_offset + (line_height * 1.1)
  render_header_line(idx,x_offset,y_offset)
  y_offset = y_offset + ( line_height * 0.1 )
  SCHEDULE[idx][:occurrences].each do |occ|
    y_offset = y_offset + line_height
    render_text_line(IMAGE, occ, x_offset, y_offset)
  end
  y_offset = y_offset + line_height*0.5
  return y_offset
end

IMAGE.rotate "90"
IMAGE.resize "2550x3300!"

offset = build_day(0,50,150)
offset = build_day(1,50,offset + 25)
offset = build_day(2,50,offset + 25)
offset = build_day(3,50,offset + 25)
offset = build_day(4,50,offset + 25)
offset = build_day(5,50,offset + 25)
offset = build_day(6,50,offset + 25)

IMAGE.write("test_poster.jpg")