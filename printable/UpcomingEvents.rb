module UpcomingEvents

  def UpcomingEvents::generate_all
    UpcomingEvents::generate_4x6
    UpcomingEvents::generate_A4
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
          :ptsize      => 13.5,
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
          :ptscale  => 0.09,
          :ptscale2 => 0.8,
          :images   => [ { :img => 'blank'} ] + Event::future.first(5).map { |x| { :img => x.image_url, :lines => x.poster_lines } }
        },
        { :type => 'footer' }
      ]
    }
  
    image = MiniMagick::Image.open(data[:background])
    image.draw_elements(data[:elements])
    image.save('upcoming_events/upcoming_events_4x6.jpg')
  end

  def UpcomingEvents::generate_A4
    data = {
      :background => 'printable/assets/a4_bg.jpg',
      :elements => [
        { :type     => 'bubble_shadow',
          :width    => 1046,
          :height   => 1046,
          :x_offset => 106,
          :y_offset => 50,
          :margin   => 1046*0.012
        },
        { :type      => 'box',
          :x_offset  => 106,
          :y_offset  => 50,
          :width     => 1046,
          :height    => 1046,
          :radius    => 100,
        },
        { :type     => 'logo',
          :x_offset => 150,
          :y_offset => 250,
          :width    => 950
        },
        { :type        => 'highlight_text',
          :text        => 'Upcoming Events!',
          :ptsize      => 27.5,
          :x_offset    => 150,
          :y_offset    => 800,
          :fill        => "\#BBBBFFFF",
          :stroke      => "\#DDDDFFDD",
          :strokewidth => 1
        },
        { :type     => 'img_array',
          :x_offset => 0,
          :y_offset => 0,
          :width    => 2411,
          :height   => 3340,
          :margin_x => 106,
          :margin_y => 50,
          :rowsize  => 2,
          :ptscale  => 0.063,
          :ptscale2 => 0.8,
          :images   => [ { :img => 'blank'} ] + Event::future.first(5).map { |x| { :img => x.image_url, :lines => x.poster_lines } }
        },
        { :type => 'footer' }
      ]
    }
  
    image = MiniMagick::Image.open(data[:background])
    image.draw_elements(data[:elements])
    image.save('upcoming_events/upcoming_events_a4.jpg')
  end

end