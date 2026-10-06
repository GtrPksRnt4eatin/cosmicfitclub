module SchedulePromo
  require 'mini_magick'
  require 'rqrcode'

  def SchedulePromo::generate_for_bot(sched)
    promo_img = SchedulePromo::generate4x5({:img=> sched.img_url, :lines=> [sched.classdef.name, "w/ " + sched.teachers.map(&:name).join(', '), sched.simple_meeting_time_description ], :location_id=>sched.location_id || 2 })
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
        :y_offset => 182,
        :ptsize   => 12,
        :strokewidth => 1,
        :kerning  => 5,
        :gravity  => "North",
        :fill     => "#E0E0E0",
        :stroke   => "#B0B0B0",
        :text     => ["Class at Hunters Point South Park!", "Live classes at the Cosmic Loft!","video.cosmicfitclub.com"][(x[:location_id].to_i) - 1]
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
        :text     => ["Center Blvd & Borden Ave. LIC, NY 11101", "669 Meeker Ave. #1F Brooklyn, NY 11222","Live Video Fitness Classes Everyday!"][(x[:location_id].to_i) -1]
      }
    ])
  end

  def SchedulePromo::generate4x6(x)
    classdef_id = x[:classdef_id] || x[:id]
    image = MiniMagick::Image.open("printable/assets/4x6_bg.jpg")
    # adjusted constants for 1200x1800 canvas (no inline math)
    image.draw_elements([
      { :type     => 'logo',
        :x_offset => 355,
        :y_offset => 22,
        :width    => 500
      },
      { :type     => "highlight_text",
        :x_offset => 0,
        :y_offset => 240,
        :ptsize   => 13,
        :strokewidth => 1,
        :kerning  => 5,
        :gravity  => "North",
        :fill     => "#E0E0E0",
        :stroke   => "#B0B0B0",
        :text     => ["Class at Hunters Point South Park!", "Live classes at the Cosmic Loft!","video.cosmicfitclub.com"][(x[:location_id] || 2).to_i - 1]
      },
      { :type     => 'image_bubble',
        :x_offset => 55,
        :y_offset => 360,
        :width    => 1083,
        :height   => 1083,
        :margin   => 6,
        :ptscale  => 0.05,
        :ptscale2 => 0.9,
        :img      => x[:img],
        :lines    => x[:lines]
      },
      { :type => 'box', 
        :width => 1180,
        :height => 111,
        :gravity => 'south',
        :y_offset => 1700,
        :color => '#00000055',
        :stroke => "#E0E0E0",
      },
      { :type     => "highlight_text",
        :x_offset => 0,
        :y_offset => 100,
        :ptsize   => 11,
        :strokewidth => 2,
        :stroke   => "#FFFFFFDD",
        :fill    => "#FFFFFFDD",
        :kerning  => 5,
        :gravity  => "South",
        :text     => "Use the QR Code to Sign up today!"
      }
    ])

    # add QR (only difference from 4x5)
    begin
      if classdef_id
        url = "https://cosmicfitclub.com/class/#{classdef_id}"
        q = RQRCode::QRCode.new(url)
        qimg = MiniMagick::Image.read q.as_png.to_blob
        qimg.to_bubble(nil) if qimg.respond_to?(:to_bubble)
        qr_w = 240
        qr_h = 240
        margin = 10
        image.overlay(qimg, qr_w, qr_h, 50, 1500)
      end

    rescue StandardError => e
      # continue without QR
    end
    # compact footer
    image.draw_footer({ :ptsize => 8, :nobottom => true })

    image
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