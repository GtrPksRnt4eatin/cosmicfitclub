
module ClassesPoster_4x6

  def ClassesPoster_4x6::generate(heading="", class_ids)
    row_y = [1250,2060,2870] if class_ids.count <= 6
    row_y = [600,1410,2220]  if class_ids.count > 6

    @@img_geometrys =      ["730x730+100+#{row_y[0]}","730x730+910+#{row_y[0]}","730x730+1720+#{row_y[0]}"]
    @@img_geometrys.concat ["730x730+100+#{row_y[1]}","730x730+910+#{row_y[1]}","730x730+1720+#{row_y[1]}"]
    @@img_geometrys.concat ["730x730+100+#{row_y[2]}","730x730+910+#{row_y[2]}","730x730+1720+#{row_y[2]}"]
    @@image = MiniMagick::Image.open("printable/assets/8.5x11_bg.jpg")

    @@image.draw_logo(100,100,2350,nil) if class_ids.count <= 6
    @@image.draw_logo(650,75,1250,nil) if class_ids.count > 6

    @@image.draw_footer(19)
    class_ids.each_with_index do |id,idx|
      geo = /(\d+)x(\d+)\+(\d+)\+(\d+)/.match(@@img_geometrys[idx])
      @@image = @@image.draw_iphone_bubble(id,geo[3].to_i,geo[4].to_i,geo[1].to_i) 
    end
    #ClassesPoster::first_class_free
    @@image
  end

  def ClassesPoster_4x6::first_class_free
    @@image.combine_options do |i|
      i.fill "\#FF0000FF"
      i.font "shared/fonts/webfonts/329F99_3_0.ttf"
      i.density 300
      i.pointsize 35
      i.gravity "South"
      i.stroke "white"
      i.strokewidth 6
      i.draw "text 0,150 \"First Class Free! Come In Today!\""
    end
  end

end
