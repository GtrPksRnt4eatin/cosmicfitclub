require 'date'
require 'mini_magick'

module SchedulePoster4x6_front

  def SchedulePoster4x6_front::get_bubble_data(data)
    val = case data[0]
    when :class
      cls = ClassDef[data[1]] or return
      { :img => cls.image[:original].url, :lines => cls.footer_lines }
    when :event
      evt = Event[data[1]] or return
      { :img => evt.image[:original].url, :lines => evt.poster_lines }
    when :staff
      stf = Staff[data[1]] or return
      { :img => stf.image[:original].url, :lines => stf.footer_lines }
    end
    p val
    val
  end
 
  def SchedulePoster4x6_front::generate(data=[[:class,40],[:class,36],[:class,32],[:class,42]],opts={})
    @@image = MiniMagick::Image.open("printable/assets/4x6_bg.jpg")
    @@image.draw_elements([
      { :type     => 'logo',
        :x_offset => 75,
        :y_offset => 75,
        :width    => 1050
      },
      { :type     => 'img_array',
        :x_offset => 0,
        :y_offset => 447,
        :width    => 1200,
        :margin   => 75,
        :rowsize  => 2,
        :ptscale  => opts[:ptscale]  || 0.083,
        :ptscale2 => opts[:ptscale2] || 0.9,
        :images   => data.map { |x| SchedulePoster4x6_front::get_bubble_data(x) }
      },
      { :type        => 'highlight_text',
        :text        => 'First Class Free! Come In Today!',
        :ptsize      => 17,
        :x_offset    => 0,
        :y_offset    => 110,
        :gravity     => 'South',
        :strokewidth => 3 
      },
      { :type => 'footer' }
    ])

    @@image.write("printable/results/4x6_front.jpg")

    @@image



    #@@logo  = MiniMagick::Image.open("printable/assets/logo.png")

    #@@image = @@image.composite(@@logo) do |c|
    #  c.compose "Over"
    #  c.geometry "1050x372+75+75"
    #end

    #@@mask = MiniMagick::Image.open("printable/assets/mask.png")
    #classdef_ids.each_with_index do |id,idx|
      #cls = ClassDef[id] or next

      #img = MiniMagick::Image.open cls.image[:medium].url
      #img.resize "500x500!"
      
      #lines = [cls.name]
      #cls.meeting_times.each_slice(2) { |a,b| lines << ( b.nil? ? a : a +", " + b ) }

      #img.to_bubble(lines)

      #img.combine_options do |i|
      #  i.fill "\#00000099"
      #  i.draw "rectangle 0,400 500,500"
      #end

      #img.combine_options do |i|
      #  i.fill "\#FFFFFFFF"
      #  i.pointsize 27
      #  i.font "shared/fonts/webfonts/329F99_3_0.ttf"
      #  i.gravity "South"
      #  i.draw "text 0,55 \"#{cls.name}\""
      #  i.draw "text 0,15 \"#{cls.meeting_times.join(", ")}\""
      #end

      #img = @@mask.composite(img,'png') do |c|
      #  c.compose "src-in"
      #  c.geometry "+0+0"
      #end

      #geo = /(\d+)x(\d+)\+(\d+)\+(\d+)/.match(@@img_geometrys[idx])
      #@@image.combine_options do |i|
      #  i.fill "\#00000099"
      #  i.draw "roundRectangle #{geo[3].to_i - 2},#{geo[4].to_i - 2} #{geo[1].to_i + geo[3].to_i + 2},#{geo[2].to_i + geo[4].to_i + 2} 50,50"
      #end

      #@@image = @@image.composite(img) do |c|
      #  c.compose "Over"
      #  c.geometry @@img_geometrys[idx]
      #end

    #end

    #@@image.combine_options do |i|
    #  i.fill "\#FF0000FF"
    #  i.font "shared/fonts/webfonts/329F99_3_0.ttf"
    #  i.density 300
    #  i.pointsize 17
    #  i.gravity "South"
    #  i.stroke "white"
    #  i.strokewidth 3
    #  i.draw "text 0,110 \"First Class Free! Come In Today!\""
    #end

    #@@image.combine_options do |i|
    #  i.fill "\#00000099"
    #  i.draw "rectangle 0,1720 1200,1800"
    #end

    #@@image.combine_options do |i|
    #  i.pointsize 37
    #  i.fill "\#FFFFFFFF"
    #  i.font "shared/fonts/webfonts/329F99_B_0.ttf"
    #  i.gravity "South"
    #  i.draw "text 0,20 \"21-36 44th Road L.I.C NY 11101  |  347-670-0019  |  cosmicfitclub.com\""
    #end


  end
  
end