require 'date'
require 'mini_magick'

module SchedulePoster4x6_front
 
  def SchedulePoster4x6_front::generate(classdef_ids=[40,36,32,42])
    @@img_geometrys = ["488x488+75+572","488x488+637+572","488x488+75+1135","488x488+637+1135"]
    @@image = MiniMagick::Image.open("printable/assets/4x6_bg.jpg")
    @@logo  = MiniMagick::Image.open("printable/assets/logo.png")

    @@image = @@image.composite(@@logo) do |c|
      c.compose "Over"
      c.geometry "1050x372+75+75"
    end

    @@mask = MiniMagick::Image.open("printable/assets/mask.png")
    classdef_ids.each_with_index do |id,idx|
      cls = ClassDef[id] or next

      img = MiniMagick::Image.open cls.image[:medium].url
      img.resize "500x500!"

      img.combine_options do |i|
        i.fill "\#00000099"
        i.draw "rectangle 0,400 500,500"
      end

      img.combine_options do |i|
        i.fill "\#FFFFFFFF"
        i.pointsize 27
        i.font "shared/fonts/webfonts/329F99_3_0.ttf"
        i.gravity "South"
        i.draw "text 0,40 \"#{cls.name}\""
      end

      img = @@mask.composite(img,'png') do |c|
        c.compose "src-in"
        c.geometry "+0+0"
      end

      geo = /(\d+)x(\d+)\+(\d+)\+(\d+)/.match(@@img_geometrys[idx])
      @@image.combine_options do |i|
        i.fill "\#00000099"
        i.draw "roundRectangle #{geo[3].to_i - 2},#{geo[4].to_i - 2} #{geo[1].to_i + geo[3].to_i + 2},#{geo[2].to_i + geo[4].to_i + 2} 50,50"
      end

      @@image = @@image.composite(img) do |c|
        c.compose "Over"
        c.geometry @@img_geometrys[idx]
      end

    end

    @@image.combine_options do |i|
      i.fill "\#00000099"
      i.draw "rectangle 0,1720 1200,1800"
    end

    @@image.combine_options do |i|
      i.pointsize 37
      i.fill "\#FFFFFFFF"
      i.font "shared/fonts/webfonts/329F99_B_0.ttf"
      i.gravity "South"
      i.draw "text 0,20 \"21-36 44th Road L.I.C NY 11101  |  347-670-0019  |  cosmicfitclub.com\""
    end

    @@image.write("printable/results/4x6_front.jpg")

    @@image

  end

  #################################### HELPERS #######################################

  def SchedulePoster4x6_front::truncate(string,max)
    return "" if string.nil?
    string.length > max ? "#{string[0...max]}..." : string
  end

  #################################### HELPERS #######################################

end