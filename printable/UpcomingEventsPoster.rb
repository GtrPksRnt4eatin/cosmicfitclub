

module UpcomingEventsPoster

  def UpcomingEventsPoster::generate()

  	boxsize  = 1000
  	x_start  = 137
  	y_start  = 90
  	x_margin = 137
  	y_margin = 85

  	dimensions = [ [x_start+boxsize+x_margin,y_start], [x_start,y_start+boxsize+y_margin], [x_start+boxsize+x_margin,y_start+boxsize+y_margin], [x_start,y_start+boxsize*2+y_margin*2], [x_start+boxsize+x_margin,y_start+boxsize*2+y_margin*2] ]

    @@image = MiniMagick::Image.open("printable/assets/a4_bg.jpg")

    Event::list_future.each_with_index do |evt,idx|
      @@image.draw_event_bubble(evt[:id], dimensions[idx][0],dimensions[idx][1] , boxsize)
    end

    @@image.bubble_shadow(boxsize,boxsize,x_start,y_start,900*0.008)
    @@image.draw_box(x_start, y_start, boxsize, boxsize, 900*0.1, 900*0.1)
    @@image.draw_logo(200,320,860)
    @@image.draw_highlight_text("Upcoming Events!",26,180,800,"None","\#BBBBFFFF","\#DDDDFFDD",2) 
    @@image.draw_footer(17.5)

    @@image

  end

  def UpcomingEventsPoster::generate_4x6()

    @@data = {
      :background => 'printable/assets/4x6_bg.jpg',
      :elements => [
        { :type     => 'img_array',
          :x_offset => 10,
          :y_offset => 280,
          :width    => 1060,
          :margin   => 10,
          :rowsize  => 4,
          :images   => [ { :img => 'blank'} ] + Event::future.first(5).map { |x| { :img => x.image_url, :lines => x.poster_lines } }
        }
      ]
    }
  
    @@image = MiniMagick::Image.open("printable/assets/4x6_bg.jpg")
    @@image.draw_elements(@@data[:elements])
  
  end

  def UpcomingEventsPoster::generate_A4()

    @@data = {
      :background => 'printable/assets/a4_bg.jpg',
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
  
    @@image = MiniMagick::Image.open("printable/assets/4x6_bg.jpg")
    @@image.draw_elements(@@data[:elements])
    @@image.save('upcoming_events_a4.jpg')
  
  end

end

