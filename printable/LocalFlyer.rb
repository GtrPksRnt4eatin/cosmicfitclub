module LocalFlyer
  
  def LocalFlyer::generate()
    schedules = ClassdefSchedule.by_week_order.select { |sch|
      sch.location.try(:name).to_s =~ /loft/i
    }.map { |sch| { :img => sch.thumb_url, :lines => sch.poster_lines } }
    events = Event.future.map { |evt|{ :img => evt.image_url, :lines => evt.poster_lines }}
    @@image = MiniMagick::Image.open("printable/assets/8.5x11_bg.jpg")
    @@image.draw_elements([
      { :type     => 'logo',
        :x_offset => 50,
        :y_offset => 50,
        :width    => 900
      },
      { :type        => 'highlight_text',
        :text        => 'A Friendly',
        :ptsize      => 20,
        :x_offset    => 1300,
        :y_offset    => 150,
        :fill        => "\#BBBBFFFF",
        :stroke      => "\#DDDDFFDD",
        :strokewidth => 1
      }, 
      { :type        => 'highlight_text',
        :text        => 'Local Circus Studio',
        :ptsize      => 20,
        :x_offset    => 1100,
        :y_offset    => 260,
        :fill        => "\#BBBBFFFF",
        :stroke      => "\#DDDDFFDD",
        :strokewidth => 1
      },
      { :type        => 'highlight_text',
        :text        => 'with Cosmic Flair!',
        :ptsize      => 20,
        :x_offset    => 1130,
        :y_offset    => 370,
        :fill        => "\#BBBBFFFF",
        :stroke      => "\#DDDDFFDD",
        :strokewidth => 1
      },
      { :type => 'box', 
        :width => 3300,
        :height => 200,
        :gravity => 'south',
        :y_offset => 3000,
        :color => '#000000BB',
        :stroke => "#000000FF",
        :strokewidth => 1
      },
      { :type        => 'highlight_text',
        :text        => 'Our Weekly Classes:',
        :ptsize      => 20,
        :x_offset    => 50,
        :y_offset    => 520,
        :fill        => "\#BBBBFFFF",
        :stroke      => "\#DDDDFFDD",
        :strokewidth => 1
      },
      { :type     => 'img_array',
        :x_offset => 0,
        :y_offset => 520,
        :width    => 2550,
        :height   => 1450,
        :margin_x => 50,
        :margin_y => 50,
        :rowsize  => 4,
        :ptscale  => 0.058,
        :ptscale2 => 1,
        :images   => schedules
      },
      { :type        => 'highlight_text',
        :text        => 'Our Upcoming Events:',
        :ptsize      => 20,
        :x_offset    => 50,
        :y_offset    => 2120,
        :fill        => "\#BBBBFFFF",
        :stroke      => "\#DDDDFFDD",
        :strokewidth => 1
      },
      { :type     => 'img_array',
        :x_offset => 0,
        :y_offset => 2130,
        :width    => 2550,
        :height   => 850,
        :margin_x => 50,
        :margin_y => 50,
        :rowsize  => 3,
        :ptscale  => 0.065,
        :ptscale2 => 1,
        :images   => events
      },
      { :type        => 'highlight_text',
        :text        => 'Aerial Point Rentals Available Anytime ($12/person/hr)',
        :ptsize      => 14,
        :x_offset    => 0,
        :y_offset    => 200,
        :gravity     => 'south',
        :fill        => "\#BBBBFFFF",
        :stroke      => "\#DDDDFFDD",
        :strokewidth => 0
      },
      { :type        => 'highlight_text',
        :text        => 'Open Training (Floor Space) Day Passes Available for $24',
        :ptsize      => 14,
        :x_offset    => 0,
        :y_offset    => 110,
        :gravity     => 'south',
        :fill        => "\#BBBBFFFF",
        :stroke      => "\#DDDDFFDD",
        :strokewidth => 0
      }, 
      { :type => 'footer' }
    ])
  end

  def LocalFlyer::generate_4x6()
    schedules = ClassdefSchedule.by_week_order.select { |sch|
      sch.location.try(:name).to_s =~ /loft/i
    }.map { |sch| { :img => sch.thumb_url, :lines => sch.poster_lines } }
    events = Event.future.map { |evt|{ :img => evt.image_url, :lines => evt.poster_lines }}
    @@image = MiniMagick::Image.open("printable/assets/4x6_bg.jpg")
    @@image.draw_elements([
      { :type     => 'logo',
        :x_offset => 25,
        :y_offset => 25,
        :width    => 420
      },
      { :type        => 'highlight_text',
        :text        => 'A Friendly Local Circus Studio',
        :ptsize      => 9,
        :x_offset    => 515,
        :y_offset    => 90,
        :fill        => "\#BBBBFFFF",
        :stroke      => "\#DDDDFFDD",
        :strokewidth => 1
      },
      { :type        => 'highlight_text',
        :text        => 'with Cosmic Flair!',
        :ptsize      => 9,
        :x_offset    => 610,
        :y_offset    => 145,
        :fill        => "\#BBBBFFFF",
        :stroke      => "\#DDDDFFDD",
        :strokewidth => 1
      },
      { :type => 'box', 
        :width => 1200,
        :height => 120,
        :gravity => 'south',
        :y_offset => 1650,
        :color => '#000000BB',
        :stroke => "#000000FF",
        :strokewidth => 1
      },
      { :type        => 'highlight_text',
        :text        => 'Our Weekly Classes:',
        :ptsize      => 8,
        :x_offset    => 25,
        :y_offset    => 220,
        :fill        => "\#BBBBFFFF",
        :stroke      => "\#DDDDFFDD",
        :strokewidth => 1
      },
      { :type     => 'img_array',
        :x_offset => 0,
        :y_offset => 220,
        :width    => 1200,
        :height   => 1100,
        :margin_x => 25,
        :margin_y => 25,
        :rowsize  => 3,
        :ptscale  => 0.057,
        :ptscale2 => 1,
        :images   => schedules
      },
      { :type        => 'highlight_text',
        :text        => 'Our Upcoming Events:',
        :ptsize      => 8,
        :x_offset    => 25,
        :y_offset    => 1335,
        :fill        => "\#BBBBFFFF",
        :stroke      => "\#DDDDFFDD",
        :strokewidth => 1
      },
      { :type     => 'img_array',
        :x_offset => 100,
        :y_offset => 1335,
        :width    => 1000,
        :height   => 335,
        :margin_x => 25,
        :margin_y => 25,
        :rowsize  => 3,
        :ptscale  => 0.07,
        :ptscale2 => 1,
        :images   => events
      },
      { :type        => 'highlight_text',
        :text        => 'Aerial Point Rentals Available Anytime ($12/person/hr)',
        :ptsize      => 6,
        :x_offset    => 0,
        :y_offset    => 100,
        :gravity     => 'south',
        :fill        => "\#BBBBFFFF",
        :stroke      => "\#DDDDFFDD",
        :strokewidth => 0
      },
      { :type        => 'highlight_text',
        :text        => 'Open Training (Floor Space) Day Passes Available for $24',
        :ptsize      => 6,
        :x_offset    => 0,
        :y_offset    => 60,
        :gravity     => 'south',
        :fill        => "\#BBBBFFFF",
        :stroke      => "\#DDDDFFDD",
        :strokewidth => 0
      }, 
      { :type => 'footer' }
    ])
  end
end