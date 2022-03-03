module SchedulePromo

  def SchedulePromo::generate_for_bot(sched)
    if sched.location_id == 3
      promo_img = SchedulePromo::generate4x5_vid({ :img=> sched.img_url, :lines=> [sched.classdef.name, "w/ " + sched.teachers.map(&:name).join(', '), sched.simple_meeting_time_description ] })
    else
      promo_img = SchedulePromo::generate4x5({ :classdef_id=>sched.classdef_id, :img=> sched.img_url, :lines=> [sched.classdef.name, "w/ " + sched.teachers.map(&:name).join(', '), sched.simple_meeting_time_description ] })
    end
    [{ :img => promo_img, :title => "#{sched.poster_lines[0]} - #{sched.teachers[0].name}.jpg" }]
  end

  def SchedulePromo::generate_all_for_bot
    arr = []
    grouped = ClassdefSchedule.all.group_by { |x| { :class=> x.classdef.name, :teacher=>x.teachers.map(&:name).join(', ') } }
    list = grouped.map { |k,v| { :teacher => k[:teacher], :img => v[0].image_url, :lines => [k[:class], "w/ " + k[:teacher], v.map(&:simple_meeting_time_description).join(", ")] } } 
    list.each{ |x| arr.push( { :img => SchedulePromo::generate4x5(x), :title =>"#{x[:lines][0]} - #{x[:teacher]}.jpg" } ) }
    arr
  end

  def SchedulePromo::generate_all()
    grouped = ClassdefSchedule.all.group_by { |x| { :class=> x.classdef.name, :teacher=>x.teachers.map(&:name).join(', ') } }
    list = grouped.map { |k,v| { :teacher => k[:teacher], :img => v[0].img_url, :lines => [k[:class], "w/ " + k[:teacher], v.map(&:simple_meeting_time_description).join(", ")] } } 
    list.each{ |x| SchedulePromo::generate4x5(x).save("vidpromos/schedules/#{x[:lines][0]} - #{x[:teacher]}.jpg") }
    list.each{ |x| SchedulePromo::generate_fbevent(x).save("vidpromos/fbevent/#{x[:lines][0]} - #{x[:teacher]}.jpg") }
    SchedulePromo::generate_allinone()
  end

  def SchedulePromo::generateall_fbevent()
    grouped = ClassdefSchedule.all.group_by { |x| { :class=> x.classdef.name, :teacher=>x.teachers.map(&:name).join(', ') } }
    list = grouped.map { |k,v| { :teacher => k[:teacher], :img => v[0].image_url, :lines => [k[:class], "w/ " + k[:teacher], v.map(&:simple_meeting_time_description).join(", ")] } } 
    list.each{ |x| SchedulePromo::generate_fbevent(x).save("vidpromos/fbevent/#{x[:lines][0]} - #{x[:teacher]}.jpg") }
  end

  def SchedulePromo::generate_allinone()
    grouped = ClassdefSchedule.all.group_by { |x| { :class=> x.classdef.name, :teacher=>x.teachers.map(&:name).join(', ') } }
    list = grouped.map { |k,v| { :teacher => k[:teacher], :img => v[0].img_url, :lines => [k[:class], "w/ " + k[:teacher], v.map(&:simple_meeting_time_description).join(", ")] } } 
    image = MiniMagick::Image.open("printable/assets/4x5_bg.jpg")
    image.draw_elements([
      { :type => 'box', 
        :width => 1080,
        :height => 100,
        :gravity => 'north',
        :color => '#00000055',
        :stroke => "#E0E0E0",
      },
      { :type     => "highlight_text",
        :x_offset => 0,
        :y_offset => 20,
        :ptsize   => 16.5,
        :kerning  => 5,
        :gravity  => "North",
        :text     => "video.cosmicfitclub.com"
      },
      { :type     => 'img_array',
        :x_offset => 0,
        :y_offset => 150,
        :width    => 1080,
        :height   => 1080,
        :margin   => 20,
        :rowsize  => 4,
        :ptscale  => 0.058,
        :ptscale2 => 1,
        :images   => [{:img=>'printable/assets/logo_tile.jpg'}] + list.concat([{:img=> 'printable/assets/cat1.jpg', :lines=>['Coffee']},{:img=> 'printable/assets/cat2.jpg', :lines=>['Donut']},])
      },
      { :type => 'box', 
        :width => 1080,
        :height => 100,
        :gravity => 'south',
        :y_offset => 1260,
        :color => '#00000055',
        :stroke => "#E0E0E0",
      },
      { :type     => "highlight_text",
        :x_offset => 0,
        :y_offset => 20,
        :ptsize   => 12.5,
        :gravity  => "South",
        :text     => "Live Video Fitness Classes Everyday!"
      }
    ])
  end

  def SchedulePromo::generate4x5_vid(x)
    image = MiniMagick::Image.open("printable/assets/4x5_bg.jpg")
    image.draw_elements([
      { :type     => 'logo',
        :x_offset => 320,
        :y_offset => 20,
        :width    => 400
      },
      { :type     => "highlight_text",
        :x_offset => 0,
        :y_offset => 175,
        :ptsize   => 16,
        :strokewidth => 1,
        :kerning  => 5,
        :gravity  => "North",
        :fill     => "#E0E0E0",
        :stroke   => "#B0B0B0",
        :text     => "video.cosmicfitclub.com"
      },
      { :type     => 'image_bubble',
        :x_offset => 50,
        :y_offset => 260,
        :width    => 975,
        :height   => 975,
        :margin   => 5,
        :ptscale  => 0.05,
        :ptscale2 => 0.9,
        :img      => x[:img],
        :lines    => x[:lines]
      },
      { :type => 'box', 
        :width => 1080,
        :height => 100,
        :gravity => 'south',
        :y_offset => 1260,
        :color => '#00000055',
        :stroke => "#E0E0E0",
      },
      { :type     => "highlight_text",
        :x_offset => 0,
        :y_offset => 20,
        :ptsize   => 12,
        :strokewidth => 2,
        :stroke   => "#FFFFFFDD",
        :fill    => "#FFFFFFDD",
        :kerning  => 5,
        :gravity  => "South",
        :text     => "Live Video Fitness Classes Everyday!"
      }
    ])
  end

  def SchedulePromo::generate4x5(x)
    image = MiniMagick::Image.open("printable/assets/4x5_bg.jpg")
    image.draw_elements([
      { :type     => 'logo',
        :x_offset => 320,
        :y_offset => 20,
        :width    => 400
      },
      { :type     => "highlight_text",
        :x_offset => 0,
        :y_offset => 175,
        :ptsize   => 16,
        :strokewidth => 1,
        :kerning  => 5,
        :gravity  => "North",
        :fill     => "#E0E0E0",
        :stroke   => "#B0B0B0",
        :text     => "Live at the Cosmic Loft"
      },
      { :type     => 'image_bubble',
        :x_offset => 50,
        :y_offset => 260,
        :width    => 975,
        :height   => 975,
        :margin   => 5,
        :ptscale  => 0.05,
        :ptscale2 => 0.9,
        :img      => x[:img],
        :lines    => x[:lines]
      },
      { :type => 'box', 
        :width => 1080,
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
        :kerning  => 5,
        :gravity  => "South",
        :text     => "669 Meeker Ave. #1F Brooklyn, NY 11222"
      }
    ])
  end

  def SchedulePromo::generate_fbevent(x)
    image = MiniMagick::Image.open("printable/assets/fb_event_bg.jpg")
    image.draw_elements([
      { :type     => 'logo',
        :x_offset => 20,
        :y_offset => 20,
        :width    => 400
      },
      { :type     => "highlight_text",
        :x_offset => 0,
        :y_offset => 175,
        :ptsize   => 18.5,
        :gravity  => "Northeast",
        :text     => "video.cosmicfitclub.com"
      },
      { :type     => 'image_bubble',
        :x_offset => 600,
        :y_offset => 50,
        :width    => 905,
        :height   => 905,
        :margin   => 6,
        :ptscale  => 0.05,
        :ptscale2 => 0.9,
        :img      => x[:img],
        :lines    => x[:lines]
      },
      { :type     => "highlight_text",
        :x_offset => 0,
        :y_offset => 20,
        :ptsize   => 12.5,
        :gravity  => "South",
        :text     => "Live Video Fitness Classes Everyday!"
      }
    ])
  end

end