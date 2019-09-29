require_relative './db_models'
require 'date'
require 'mini_magick'

items = Scheduling::get_all_between(Time.parse("2019-09-27"),Time.parse("2019-10-04"))
arr = []
items.each { |k,v| arr << { :day => k, :occurrences => v.sort_by { |x| x[:starttime] } } }

SCHEDULE = arr.sort_by { |x| x[:day] }

puts JSON.pretty_generate SCHEDULE
#SCHEDULE = JSON.parse '[{"day":"2019-09-22","occurrences":[{"day":"2019-09-22","starttime":"2019-09-22T14:00:00-04:00","endtime":"2019-09-22T16:00:00-04:00","headcount":4,"exception":null,"type":"classoccurrence","sched_id":424,"duration":7200.0,"classdef_id":46,"title":"Group Acrobatics(Open Level)","instructors":[{"id":18,"name":"Ben Klein"}],"capacity":20},{"day":"2019-09-22","starttime":"2019-09-22T16:00:00-04:00","endtime":"2019-09-22T20:00:00-04:00","headcount":0,"exception":null,"type":"classoccurrence","sched_id":423,"duration":14400.0,"classdef_id":78,"title":"Open Studio","instructors":[{"id":18,"name":"Ben Klein"}],"capacity":20},{"day":"2019-09-22","starttime":"2019-09-22T16:00:00-04:00","endtime":"2019-09-22T19:00:00-04:00","headcount":2,"exception":null,"type":"classoccurrence","sched_id":324,"duration":10800.0,"classdef_id":99,"title":"Juggling & Flow Arts Jam","instructors":[{"id":30,"name":"Olga Glazman"}],"capacity":20}]},{"day":"2019-09-23","occurrences":[{"day":"2019-09-23","starttime":"2019-09-23T18:00:00-04:00","endtime":"2019-09-23T19:00:00-04:00","headcount":5,"exception":null,"type":"classoccurrence","sched_id":509,"duration":3600.0,"classdef_id":130,"title":"Flexibility, Balance and Motion","instructors":[{"id":92,"name":"Aryn Shelander"}],"capacity":20},{"day":"2019-09-23","starttime":"2019-09-23T18:30:00-04:00","endtime":"2019-09-23T19:30:00-04:00","headcount":0,"exception":null,"type":"classoccurrence","sched_id":222,"duration":3600.0,"classdef_id":36,"title":"Cosmic Calisthenics ","instructors":[{"id":11,"name":"Rick Seedman "}],"capacity":20},{"day":"2019-09-23","starttime":"2019-09-23T19:30:00-04:00","endtime":"2019-09-23T20:30:00-04:00","headcount":1,"exception":null,"type":"classoccurrence","sched_id":420,"duration":3600.0,"classdef_id":40,"title":"Cosmic Yoga ","instructors":[{"id":1,"name":"Joy Chen"}],"capacity":20},{"day":"2019-09-23","starttime":"2019-09-23T20:30:00-04:00","endtime":"2019-09-23T21:30:00-04:00","headcount":0,"exception":null,"type":"classoccurrence","sched_id":421,"duration":3600.0,"classdef_id":32,"title":"Core Fusion: Total Body Conditoning","instructors":[{"id":1,"name":"Joy Chen"}],"capacity":20}]},{"day":"2019-09-24","occurrences":[{"day":"2019-09-24","starttime":"2019-09-24T16:30:00-04:00","endtime":"2019-09-24T17:30:00-04:00","headcount":1,"exception":null,"type":"classoccurrence","sched_id":498,"duration":3600.0,"classdef_id":122,"title":"Tumbling for Kids 6-13yrs","instructors":[{"id":80,"name":"Emily Henrie"}],"capacity":20},{"day":"2019-09-24","starttime":"2019-09-24T18:00:00-04:00","endtime":"2019-09-24T22:00:00-04:00","headcount":0,"exception":null,"type":"classoccurrence","sched_id":500,"duration":14400.0,"classdef_id":123,"title":"Tuesday Open Studio","instructors":[{"id":78,"name":"Kathryn McKenzie"}],"capacity":20},{"day":"2019-09-24","starttime":"2019-09-24T18:30:00-04:00","endtime":"2019-09-24T19:30:00-04:00","headcount":16,"exception":null,"type":"classoccurrence","sched_id":460,"duration":3600.0,"classdef_id":62,"title":"Free Yoga at Hunters Point Park South","instructors":[{"id":1,"name":"Joy Chen"}],"capacity":55},{"day":"2019-09-24","starttime":"2019-09-24T18:30:00-04:00","endtime":"2019-09-24T20:00:00-04:00","headcount":0,"exception":null,"type":"classoccurrence","sched_id":461,"duration":5400.0,"classdef_id":116,"title":"Intermediate Washing Machines and Flows","instructors":[{"id":72,"name":"Juliana VonRainbowpants"}],"capacity":20},{"day":"2019-09-24","starttime":"2019-09-24T20:00:00-04:00","endtime":"2019-09-24T21:30:00-04:00","headcount":0,"exception":null,"type":"classoccurrence","sched_id":507,"duration":5400.0,"classdef_id":119,"title":"Icarian Pops and Whips- Intermediate L-Basing Class","instructors":[{"id":15,"name":"Jeremy Martin"}],"capacity":20}]},{"day":"2019-09-25","occurrences":[{"day":"2019-09-25","starttime":"2019-09-25T13:00:00-04:00","endtime":"2019-09-25T17:00:00-04:00","headcount":0,"exception":null,"type":"classoccurrence","sched_id":427,"duration":14400.0,"classdef_id":78,"title":"Open Studio","instructors":[{"id":79,"name":"Ramon Frias"}],"capacity":20},{"day":"2019-09-25","starttime":"2019-09-25T16:30:00-04:00","endtime":"2019-09-25T18:00:00-04:00","headcount":0,"exception":null,"type":"classoccurrence","sched_id":458,"duration":5400.0,"classdef_id":115,"title":"Cosmic Circus Kids","instructors":[{"id":30,"name":"Olga Glazman"}],"capacity":20},{"day":"2019-09-25","starttime":"2019-09-25T18:30:00-04:00","endtime":"2019-09-25T19:30:00-04:00","headcount":2,"exception":null,"type":"classoccurrence","sched_id":268,"duration":3600.0,"classdef_id":45,"title":"Acro Drills and Fundamentals (Beginner)","instructors":[{"id":1,"name":"Joy Chen"}],"capacity":20},{"day":"2019-09-25","starttime":"2019-09-25T18:30:00-04:00","endtime":"2019-09-25T19:30:00-04:00","headcount":0,"exception":null,"type":"classoccurrence","sched_id":548,"duration":3600.0,"classdef_id":36,"title":"Cosmic Calisthenics ","instructors":[{"id":11,"name":"Rick Seedman "}],"capacity":20},{"day":"2019-09-25","starttime":"2019-09-25T19:30:00-04:00","endtime":"2019-09-25T20:25:00-04:00","headcount":0,"exception":null,"type":"classoccurrence","sched_id":147,"duration":3300.0,"classdef_id":74,"title":"Handstands","instructors":[{"id":1,"name":"Joy Chen"}],"capacity":20},{"day":"2019-09-25","starttime":"2019-09-25T20:30:00-04:00","endtime":"2019-09-25T22:00:00-04:00","headcount":0,"exception":null,"type":"classoccurrence","sched_id":267,"duration":5400.0,"classdef_id":33,"title":"Intermediate Standing Acrobatics ","instructors":[{"id":17,"name":"Brian Konash "}],"capacity":20}]},{"day":"2019-09-26","occurrences":[{"day":"2019-09-26","starttime":"2019-09-26T10:00:00-04:00","endtime":"2019-09-26T16:00:00-04:00","headcount":0,"exception":null,"type":"classoccurrence","sched_id":436,"duration":21600.0,"classdef_id":78,"title":"Open Studio","instructors":[{"id":79,"name":"Ramon Frias"}],"capacity":20},{"type":"eventsession","day":"2019-09-26","starttime":"2019-09-26T17:30:00-04:00","endtime":"2019-09-26T18:30:00-04:00","title":"Session 2","event_title":"4-Week Aerial Series with Sylvana Tapia","event_id":403,"multisession_event":true},{"day":"2019-09-26","starttime":"2019-09-26T18:30:00-04:00","endtime":"2019-09-26T19:30:00-04:00","headcount":0,"exception":{"id":516,"classdef_id":32,"classdef_name":"Core Fusion: Total Body Conditoning","teacher_id":9,"teacher_name":"Ge Wang ","starttime":"2019-09-26T18:30:00-04:00","original_starttime":"2019-09-26T18:30:00-04:00","cancelled":false,"hidden":false,"type":"substitute"},"type":"classoccurrence","sched_id":490,"duration":3600.0,"classdef_id":32,"title":"Core Fusion: Total Body Conditoning","instructors":[{"id":9,"name":"Ge Wang "}],"capacity":20},{"day":"2019-09-26","starttime":"2019-09-26T19:30:00-04:00","endtime":"2019-09-26T20:30:00-04:00","headcount":1,"exception":null,"type":"classoccurrence","sched_id":456,"duration":3600.0,"classdef_id":107,"title":"Tumbling Hour","instructors":[{"id":80,"name":"Emily Henrie"}],"capacity":20},{"type":"eventsession","day":"2019-09-26","starttime":"2019-09-26T20:30:00-04:00","endtime":"2019-09-26T22:00:00-04:00","title":"Session #2","event_title":"Acrodance- 4 week series with Dave Paris","event_id":402,"multisession_event":true}]},{"day":"2019-09-27","occurrences":[{"day":"2019-09-27","starttime":"2019-09-27T13:00:00-04:00","endtime":"2019-09-27T18:00:00-04:00","headcount":0,"exception":null,"type":"classoccurrence","sched_id":454,"duration":18000.0,"classdef_id":78,"title":"Open Studio","instructors":[{"id":79,"name":"Ramon Frias"}],"capacity":20},{"day":"2019-09-27","starttime":"2019-09-27T18:00:00-04:00","endtime":"2019-09-27T19:00:00-04:00","headcount":1,"exception":null,"type":"classoccurrence","sched_id":499,"duration":3600.0,"classdef_id":42,"title":"Acroyoga Basics (Beginner)","instructors":[{"id":81,"name":"Mary Aranas"}],"capacity":20},{"day":"2019-09-27","starttime":"2019-09-27T19:00:00-04:00","endtime":"2019-09-27T20:00:00-04:00","headcount":0,"exception":null,"type":"classoccurrence","sched_id":457,"duration":3600.0,"classdef_id":114,"title":"Intro to Thai Massage and Bodywork","instructors":[{"id":81,"name":"Mary Aranas"}],"capacity":20},{"day":"2019-09-27","starttime":"2019-09-27T20:00:00-04:00","endtime":"2019-09-27T21:30:00-04:00","headcount":0,"exception":null,"type":"classoccurrence","sched_id":508,"duration":5400.0,"classdef_id":44,"title":"Hand2Hand & Foot2Hand (Intermediate)","instructors":[{"id":18,"name":"Ben Klein"}],"capacity":20}]},{"day":"2019-09-28","occurrences":[{"day":"2019-09-28","starttime":"2019-09-28T09:00:00-04:00","endtime":"2019-09-28T10:00:00-04:00","headcount":0,"exception":null,"type":"classoccurrence","sched_id":492,"duration":3600.0,"classdef_id":121,"title":"Beginner Yoga","instructors":[{"id":84,"name":"Astrid Locker"}],"capacity":20},{"day":"2019-09-28","starttime":"2019-09-28T10:00:00-04:00","endtime":"2019-09-28T11:30:00-04:00","headcount":1,"exception":null,"type":"classoccurrence","sched_id":455,"duration":5400.0,"classdef_id":96,"title":"Tai-Chi","instructors":[{"id":28,"name":"Daria FM"}],"capacity":20},{"type":"eventsession","day":"2019-09-28","starttime":"2019-09-28T12:00:00-04:00","endtime":"2019-09-28T13:00:00-04:00","title":"Session 4","event_title":"Baby and Me Yoga: 4 week September series","event_id":399,"multisession_event":true},{"day":"2019-09-28","starttime":"2019-09-28T12:00:00-04:00","endtime":"2019-09-28T13:00:00-04:00","headcount":0,"exception":null,"type":"classoccurrence","sched_id":514,"duration":3600.0,"classdef_id":117,"title":"Baby & Me Yoga","instructors":[{"id":1,"name":"Joy Chen"}],"capacity":20},{"day":"2019-09-28","starttime":"2019-09-28T13:00:00-04:00","endtime":"2019-09-28T15:00:00-04:00","headcount":0,"exception":null,"type":"classoccurrence","sched_id":332,"duration":7200.0,"classdef_id":93,"title":"Family Acrobatics & Open Play","instructors":[{"id":72,"name":"Juliana VonRainbowpants"}],"capacity":20},{"day":"2019-09-28","starttime":"2019-09-28T15:00:00-04:00","endtime":"2019-09-28T16:00:00-04:00","headcount":0,"exception":null,"type":"classoccurrence","sched_id":331,"duration":3600.0,"classdef_id":42,"title":"Acroyoga Basics (Beginner)","instructors":[{"id":72,"name":"Juliana VonRainbowpants"}],"capacity":20},{"day":"2019-09-28","starttime":"2019-09-28T15:00:00-04:00","endtime":"2019-09-28T20:00:00-04:00","headcount":0,"exception":null,"type":"classoccurrence","sched_id":497,"duration":18000.0,"classdef_id":78,"title":"Open Studio","instructors":[{"id":18,"name":"Ben Klein"}],"capacity":20},{"type":"eventsession","day":"2019-09-28","starttime":"2019-09-28T20:00:00-04:00","endtime":"2019-09-28T21:30:00-04:00","title":"Candlelight Yoga with Live Music","event_title":"Candlelight yoga with Live Music, Wine & Cheese","event_id":400,"multisession_event":false}]}]'
IMAGE    = MiniMagick::Image.open("../shared/img/background-blu.jpg")

LINE_HEIGHT = 60


def truncate(string,max)
  string.length > max ? "#{string[0...max]}..." : string
end

def parse_day(str)
  dt = DateTime.parse(str)
  dt.strftime("%a %b %e")
end

def parse_time(occ)
  start   = DateTime.parse(occ["starttime"])
  finish  = DateTime.parse(occ["endtime"])
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

def render_text_line(occ, x_offset, y_offset)
  font_size
  col1_x, col2_x, col3_x = 75, 600, 1750
  col2_trunc, col3_trunc = 53, 28

  IMAGE.combine_options do |i|
    i.pointsize 42
    i.font "../shared/fonts/webfonts/329F99_3_0.ttf"
    case occ['type']
    when 'classoccurrence'
      i.fill "\#FFFFFFFF"
      i.draw "text #{x_offset + col1_x },#{y_offset} '#{line}'"
      i.draw "text #{x_offset + col2_x },#{y_offset} '#{truncate(occ['title'],col2_trunc)}'"
      i.draw "text #{x_offset + col3_x },#{y_offset} 'w/ #{truncate(occ['instructors'][0]['name'],col3_trunc)}'"
    when 'eventsession'
      i.fill "\#FFFFAAFF"
      i.draw "text #{x_offset + col1_x },#{y_offset} '#{line}'"
      i.draw "text #{x_offset + col2_x },#{y_offset} '#{truncate(occ['event_title'],col2_trunc)}'"
      i.draw "text #{x_offset + col3_x },#{y_offset} '#{truncate(occ['title'],col3_trunc)}'"
    when 'rental'
    end
  end
end

def build_day(idx, x_offset, y_offset)
  line_height = 60
  box_width = 2450
  box_height = (line_height * 0.7) + ( line_height * SCHEDULE[idx]["occurrences"].count ) + line_height
  draw_box_raw(x_offset, y_offset, box_width, box_height )
  x_offset = x_offset + 20
  y_offset = y_offset + (line_height * 1.1)
  IMAGE.combine_options do |i|
    i.fill "\#FFFFFFFF"
    i.font "../shared/fonts/webfonts/329F99_3_0.ttf"
    i.pointsize 55
    i.draw "text #{x_offset},#{y_offset} '#{parse_day(SCHEDULE[idx]["day"])}'"
    y_offset = y_offset + ( line_height * 0.1 )
    SCHEDULE[idx]["occurrences"].each do |occ|
      y_offset = y_offset + line_height
      i.pointsize 42
      line = "#{parse_time(occ)}"
      if occ['type']=='classoccurrence' then
        i.draw "text #{x_offset + 75 },#{y_offset} '#{line}'"
        i.draw "text #{x_offset + 600 },#{y_offset} '#{truncate(occ['title'],53)}'"
        i.draw "text #{x_offset + 1750 },#{y_offset} 'w/ #{truncate(occ['instructors'][0]['name'],25)}'"
      end
      if occ['type']=='eventsession' then
        i.draw "text #{x_offset + 75 },#{y_offset} '#{line}'"
        i.draw "text #{x_offset + 600 },#{y_offset} '#{truncate(occ['event_title'],53)}'"
        i.draw "text #{x_offset + 1750 },#{y_offset} '#{truncate(occ['title'],28)}'"
      end
    end
    y_offset = y_offset + line_height*0.5
  end
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