  module DailyPromo
  
    def DailyPromo::generate_for_bot(date)
      date ||= Date.today
      date = Date.parse(date) if date.is_a? String
      list = Scheduling::flat_list(date,date+1)
      list.reject! { |x| x[:classdef_id]==173 } # no point rentals on flier
      list.uniq!   { |x| [ x[:classdef_id], x[:starttime]] } # dont show two entries for hybrid video/live clsses
      DailyPromo::generateStory(date,list)
    end
  
    def DailyPromo::generate_all(date)
      date ||= Date.today
      list = Scheduling::flat_list(date,date+1)
      DailyPromo::generate4x5(date,list).save("vidpromos/daily/#{date.to_s}.jpg")
    end
  
    def DailyPromo::build_list_header(x_offset,y_offset,width,height,margin,title)
      [ 
        { :type => 'box',
          :x_offset => x_offset + margin,
          :y_offset => y_offset + margin,
          :stroke => "#E0E0E0",
          :width => width - (2*margin),
          :height => height - (2*margin),
          :color  => "#00000099",
          :radius => 10
        },
        { :type => 'text_header',
          :gravity => 'North',
          :ptsize =>  height/11,
          :x_offset => 0,
          :y_offset => y_offset + (height/11)*4,
          :color =>"#E0E0E0",
          :text     => title
        }
      ]    
    end
  
    def DailyPromo::build_list_items(x_offset,y_offset,width,height,margin,list)
      usableHeight = (height - margin*list.count+1)
      itemHeight = height
      list.each_with_index.map { |x,i| [
        { :type => "box",
          :x_offset => x_offset + margin,
          :y_offset => y_offset + margin + ( i * (itemHeight + margin) ),
          :width    => width - (margin * 2),
          :height   => itemHeight,
          :color    => '#00000099',
          :stroke => "#E0E0E0",
          :radius   => 10
        },
        { :type => 'image_bubble',
          :x_offset => x_offset + (2*margin),
          :y_offset => y_offset + (2*margin) + ( i * (itemHeight + margin) ),
          :width    => itemHeight - (2*margin),
          :height   => itemHeight - (2*margin),
          :margin   => 3,
          :img      => x[:thumb_url],
          :lines    => [],
          :geometry => ""
        },
        { :type => 'paragraph',
          :font => "shared/fonts/webfonts/329F99_3_0.ttf",
          :x_offset => x_offset + (2*margin) + (itemHeight - (2*margin)) + margin,
          :y_offset => y_offset + (2*margin) + ( i * (itemHeight + margin) ) + itemHeight/6,
          :ptsize   => itemHeight/20,
          :spacing  => 12,
          :color    => "#E0E0E0",
          :text     => "#{x[:starttime].strftime("%l:%M %p")}\r\n#{x[:title]}\r\nw/ #{x[:instructors] && x[:instructors].map do |x| x[:name] end.join(', ')} #{x[:exception] && x[:exception][:changes][:sub] && ' (sub)'}"
        }
      ]}.flatten
    end
  
    def DailyPromo::generate4x5(date,list)
      image = MiniMagick::Image.open("printable/assets/4x5_bg.jpg")
      image.draw_elements([
        { :type => 'box', 
          :width => 1079,
          :height => 350,
          :gravity => 'south',
          :color => '#00000055',
          :stroke => "#E0E0E0",
        },
        { :type     => 'logo',
          :x_offset => 240,
          :y_offset => 20,
          :width    => 600
        },
        { :type     => "highlight_text",
          :x_offset => 0,
          :y_offset => 260,
          :ptsize   => 15,
          :kerning  => 8,
          :gravity  => "North",
          :strokewidth => 2,
          :stroke   => "#FFFFFFDD",
          :fill    => "#FFFFFFDD",
          :text     => "Classes at the Cosmic Loft!"
        },
        { :type => 'box', 
          :width => 1079,
          :height => 100,
          :gravity => 'south',
          :y_offset => 1260,
          :color => '#00000055',
          :stroke => "#E0E0E0",
        },
        { :type     => "highlight_text",
          :x_offset => 0,
          :y_offset => 20,
          :ptsize   => 10,
          :strokewidth => 2,
          :stroke   => "#FFFFFFDD",
          :fill    => "#FFFFFFDD",
          :gravity  => "South",
          :kerning  => 5,
          :text     => "669 Meeker Ave. #1F Brooklyn, NY 11222"
        }
      ])
      offset = case list.count
      when 1; 565 
      when 2; 465
      when 3; 365
      else;   365
      end
      image.draw_elements(DailyPromo::build_list_header(0,offset,1080,130,30,date.strftime("%A %b %d %Y")))
      image.draw_elements(DailyPromo::build_list_items(0,offset+100,1080,220,30,list))
    end

    def DailyPromo::generateStory(date,list)
      image = MiniMagick::Image.open("printable/assets/1080x1920_bg.jpg")
      image.draw_elements([
        { :type => 'box', 
          :width => 1079,
          :height => 350,
          :gravity => 'south',
          :color => '#00000055',
          :stroke => "#E0E0E0",
        },
        { :type     => 'logo',
          :x_offset => 240,
          :y_offset => 20,
          :width    => 600
        },
        { :type     => "highlight_text",
          :x_offset => 0,
          :y_offset => 260,
          :ptsize   => 15,
          :kerning  => 8,
          :gravity  => "North",
          :strokewidth => 2,
          :stroke   => "#FFFFFFDD",
          :fill    => "#FFFFFFDD",
          :text     => "Classes at the Cosmic Loft!"
        },
        { :type => 'box', 
          :width => 1079,
          :height => 100,
          :gravity => 'south',
          :y_offset => 1260,
          :color => '#00000055',
          :stroke => "#E0E0E0",
        },
        { :type     => "highlight_text",
          :x_offset => 0,
          :y_offset => 20,
          :ptsize   => 10,
          :strokewidth => 2,
          :stroke   => "#FFFFFFDD",
          :fill    => "#FFFFFFDD",
          :gravity  => "South",
          :kerning  => 5,
          :text     => "669 Meeker Ave. #1F Brooklyn, NY 11222"
        }
      ])
      offset = case list.count
      when 1; 565 
      when 2; 465
      when 3; 365
      else;   365
      end
      image.draw_elements(DailyPromo::build_list_header(0,offset,1080,130,30,date.strftime("%A %b %d %Y")))
      image.draw_elements(DailyPromo::build_list_items(0,offset+100,1080,220,30,list))
    end

  end
