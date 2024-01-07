module UpcomingEvents

  def UpcomingEvents::generate_for_bot()
    arr = []
    #arr.push({ :img => UpcomingEvents::generate_4x5, :title => "UpcomingEvents_4x5"  })
    arr.push({ :img => UpcomingEvents::generate_a4, :title => "UpcomingEvents_a4"  })
  end

  def UpcomingEvents::generate_all
    UpcomingEvents::generate_4x6
    UpcomingEvents::generate_a4
    UpcomingEvents::generate_a4_landscape
  end

  def UpcomingEvents::generate_4x5
    data = {
      :background => 'printable/assets/4x5_bg.jpg',
      :elements => [
        { :type     => 'bubble_shadow',
          :width    => 425,
          :height   => 417,
          :x_offset => 90,
          :y_offset => 25,
          :margin   => 425*0.01
        },
        { :type      => 'box',
          :x_offset  => 90,
          :y_offset  => 25,
          :width     => 425,
          :height    => 417,
          :radius    => 45,
        },
        { :type     => 'logo',
          :x_offset => 110,
          :y_offset => 130,
          :width    => 380
        },
        { :type        => 'highlight_text',
          :text        => 'Upcoming Events!',
          :ptsize      => 9.8,
          :x_offset    => 110,
          :y_offset    => 360,
          :stroke      => "\#DDDDFFDD",
          :fill        => "\#BBBBFFFF",
          :strokewidth => 1
        },
        { :type       => 'img_array',
          :x_offset   => 40,
          :y_offset   => 0,
          :width      => 1000,
          :height     => Event::future.count == 3 ? 1000 : 1351,
          :margin_x   => 50,
          :margin_y   => 25, 
          :rowsize    => 2,
          :ptscale    => 0.045,
          :ptscale2   => 1,
          :images     => [ { :img => 'blank'} ] + Event::future.first(5).map { |x| { :img => x.image_url, :lines => x.poster_lines } }
        }
      ]
    }
  
    image = MiniMagick::Image.open(data[:background])
    image.draw_elements(data[:elements])
    #image.save('upcoming_events/upcoming_events_4x5.jpg')
    image
  end

  def UpcomingEvents::generate_4x6
    data = {
      :background => 'printable/assets/4x6_bg.jpg',
      :elements => [
        { :type     => 'bubble_shadow',
          :width    => 525,
          :height   => 516,
          :x_offset => 50,
          :y_offset => 50,
          :margin   => 900*0.008
        },
        { :type      => 'box',
          :x_offset  => 50,
          :y_offset  => 50,
          :width     => 525,
          :height    => 516,
          :radius    => 45,
        },
        { :type     => 'logo',
          :x_offset => 75,
          :y_offset => 160,
          :width    => 480
        },
        { :type        => 'highlight_text',
          :text        => 'Upcoming Events!',
          :ptsize      => 12.5,
          :x_offset    => 75,
          :y_offset    => 420,
          :fill        => "\#BBBBFFFF",
          :stroke      => "\#DDDDFFDD",
          :strokewidth => 1
        },
        { :type     => 'img_array',
          :x_offset => 0,
          :y_offset => 0,
          :width    => 1200,
          :height   => 1750,
          :margin   => 50,
          :rowsize  => 2,
          :ptscale  => 0.045,
          :ptscale2 => 1,
          :images   => [ { :img => 'blank'} ] + Event::future.first(5).map { |x| { :img => x.image_url, :lines => x.poster_lines } }
        },
        { :type => 'footer' }
      ]
    }
  
    image = MiniMagick::Image.open(data[:background])
    image.draw_elements(data[:elements])
    image.save('upcoming_events/upcoming_events_4x6.jpg')
  end

  def UpcomingEvents::generate_a4
    data = {
      :background => 'printable/assets/a4_bg.jpg',
      :elements => [
        { :type     => 'bubble_shadow',
          :width    => 1046,
          :height   => 1046,
          :x_offset => 106,
          :y_offset => 50 + (Event::future.count == 3 ? 650 : 0),
          :margin   => 1046*0.012
        },
        { :type      => 'box',
          :x_offset  => 106,
          :y_offset  => 50 + (Event::future.count == 3 ? 650 : 0),
          :width     => 1046,
          :height    => 1046,
          :radius    => 100,
        },
        { :type     => 'logo',
          :x_offset => 150,
          :y_offset => 250 + (Event::future.count == 3 ? 650 : 0),
          :width    => 950
        },
        { :type        => 'highlight_text',
          :text        => 'Upcoming Events!',
          :ptsize      => 27.3,
          :x_offset    => 148,
          :y_offset    => 800 + (Event::future.count == 3 ? 600 : 0),
          :fill        => "\#BBBBFFFF",
          :stroke      => "\#DDDDFFDD",
          :strokewidth => 1
        },
        { :type     => 'img_array',
          :x_offset => 0,
          :y_offset => Event::future.count == 3 ? 600 : 0,
          :width    => 2411,
          :height   => Event::future.count == 3 ? 2411 : 3340,
          :margin_x => 106,
          :margin_y => Event::future.count == 3 ? 106 : 50,
          :rowsize  => 2,
          :ptscale  => 0.052,
          :ptscale2 => 0.94,
          :images   => [ { :img => 'blank'} ] + Event::future.first(5).map { |x| { :img => x.image_url, :lines => x.poster_lines } }
        },
        { :type => 'footer' }
      ]
    }
  
    image = MiniMagick::Image.open(data[:background])
    image.draw_elements(data[:elements])
    #image.save('upcoming_events/upcoming_events_a4.jpg')
    image
  end

  def UpcomingEvents::generate_a4_landscape
    data = {
      :background => 'printable/assets/a4_bg.jpg',
      :elements => [
        { :type     => 'bubble_shadow',
          :width    => 1045,
          :height   => 1070,
          :x_offset => 75,
          :y_offset => 90,
          :margin   => 1045*0.012
        },
        { :type      => 'box',
          :x_offset  => 75,
          :y_offset  => 90,
          :width     => 1045,
          :height    => 1070,
          :radius    => 100,
        },
        { :type     => 'logo',
          :x_offset => 120,
          :y_offset => 290,
          :width    => 950
        },
        { :type        => 'highlight_text',
          :text        => 'Upcoming Events!',
          :ptsize      => 27.5,
          :x_offset    => 120,
          :y_offset    => 840,
          :fill        => "\#BBBBFFFF",
          :stroke      => "\#DDDDFFDD",
          :strokewidth => 1
        },
        { :type     => 'img_array',
          :x_offset => 0,
          :y_offset => 0,
          :width    => 3437,
          :height   => 2411,
          :margin_x => 75,
          :margin_y => 90,
          :rowsize  => 3,
          :ptscale  => 0.062,
          :ptscale2 => 0.81,
          :images   => [ { :img => 'blank'} ] + Event::future.first(5).map { |x| { :img => x.image_url, :lines => x.poster_lines } }
        }
      ]
    }
  
    image = MiniMagick::Image.open(data[:background])
    image.rotate(90)
    image.draw_elements(data[:elements])
    image.save('upcoming_events/upcoming_events_a4_landscape.jpg')
  end

end
