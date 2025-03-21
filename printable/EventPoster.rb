require 'date'
require 'fileutils'
require 'mini_magick'

module EventPoster

  def EventPoster::generate_for_bot(event)
    arr = []
    arr.push({ :img => EventPoster::generate4x5(event.id),       :title => "#{event.name.truncate(12)}_fbpost"  })
    #arr.push({ :img => EventPoster::generate1080x1080(event.id), :title => "#{event.name.truncate(12)}_square"  })
    #arr.push({ :img => EventPoster::generate1080x1920(event.id), :title => "#{event.name.truncate(12)}_story"   })
    #arr.push({ :img => EventPoster::generateFBEvent(event.id),   :title => "#{event.name.truncate(12)}_fbevent" })
  end

  def EventPoster::generate_all(event_id)
    FileUtils.mkdir_p "printable/results/events/event_#{event_id}"
    EventPoster::generate4x5(event_id).save("events/event_#{event_id}/event_#{event_id}_4x5.jpg");             p "4x5 complete"
    EventPoster::generate4x6(event_id).save("events/event_#{event_id}/event_#{event_id}_4x6.jpg");             p "4x6 complete"
    EventPoster::generate1080x1080(event_id).save("events/event_#{event_id}/event_#{event_id}_1080x1080.jpg"); p "1x1 complete"
    EventPoster::generate1920x1080(event_id);                                                                  p "HD complete"
    EventPoster::generate1080x1920(event_id).save("events/event_#{event_id}/event_#{event_id}_1080x1920.jpg"); p "Story complete"
    EventPoster::generateFBEvent(event_id).save("events/event_#{event_id}/event_#{event_id}_fbevent.jpg");     p "FB Event complete"
    EventPoster::generate_a4(event_id).save("events/event_#{event_id}/event_#{event_id}_a4.jpg");              p "A4 complete"
  end

  def EventPoster::generate4x5(event_id)
    @@image = MiniMagick::Image.open("printable/assets/4x5_bg.jpg")
    @@image.draw_elements([
      { :type     => 'logo',
        :x_offset => 280,
        :y_offset => 30,
        :width    => 520
      },
      { :type     => 'event_bubble',
        :event_id => event_id,
        :x_offset => 50,
        :y_offset => 260,
        :width    => 975,
        :margin   => 5,
        :ptscale  => 0.05,
        :ptscale2 => 0.043
      },
      { :type => 'box', 
        :width => 1080,
        :height => 100,
        :gravity => 'south',
        :y_offset => 1260,
        :color => '#00000055',
        :stroke => "#E0E0E0"
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
        :text     => "cosmicfitclub.com/#{Event[event_id].short_path}"
      }
    ])
  end
 
  def EventPoster::generate4x6(event_id)
    @@image = MiniMagickd::Image.open("printable/assets/4x6_bg.jpg")
    @@image.draw_elements([
      { :type     => 'logo',
        :x_offset => 50,
        :y_offset => 50,
        :width    => 1100
      },
      { :type     => 'event_bubble',
        :event_id => event_id,
        :x_offset => 50,
        :y_offset => 520,
        :width    => 1100,
        :ptscale  => 0.05,
        :ptscale2 => 0.043,
        :margin   => 3
      },
      { :type     => 'highlight_text',
        :text     => "cosmicfitclub.com/#{Event[event_id].short_path}",
        :x_offset => 0,
        :y_offset => 100,
        :gravity  => 'south',
        :ptsize   => 18
      },
      { :type     => 'footer' }
    ])
  end

  def EventPoster::generate1080x1080(event_id)
    @@image = MiniMagick::Image.open("printable/assets/1080x1080_bg.jpg")
    @@image.draw_elements([
      { :type     => 'event_bubble',
        :event_id => event_id,
        :x_offset => 20,
        :y_offset => 20,
        :width    => 1040,
        :margin   => 3,
        :ptscale  => 0.05,
        :ptscale2 => 0.04
      }
    ])
  end

  def EventPoster::generate1080x1920(event_id)
    @@image = MiniMagick::Image.open("printable/assets/1080x1920_bg.jpg")
    @@image.draw_elements([
      { :type     => 'logo',
        :x_offset => 240,
        :y_offset => 240,
        :width    => 600
      },
      { :type     => 'highlight_text',
        :text     => "cosmicfitclub.com/#{Event[event_id].short_path}",
        :x_offset => 0,
        :y_offset => 470,
        :gravity  => 'north',
        :stroke   => "#FFFFFFDD",
        :fill     => "#FFFFFFDD",
        :ptsize   => 14
      },
      { :type     => 'event_bubble',
        :event_id => event_id,
        :x_offset => 50,
        :y_offset => 570,
        :width    => 980,
        :ptscale  => 0.05,
        :ptscale2 => 0.043
      }
    ])
  end

  def EventPoster::generate_a4(event_id)
    @@image = MiniMagick::Image.open("printable/assets/a4_bg.jpg")
    @@image.draw_elements([
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
        { :type     => 'event_bubble',
          :event_id => event_id,
          :x_offset => 50,
          :y_offset => 570,
          :width    => 980,
          :ptscale  => 0.05,
          :ptscale2 => 0.043
        },
        { :type     => 'img_array',
          :x_offset => 0,
          :y_offset => 0,
          :width    => 2411,
          :height   => 3340,
          :margin_x => 106,
          :margin_y => 50,
          :rowsize  => 2,
          :ptscale  => 0.05,
          :ptscale2 => 0.8,
          :images   => [ { :img => 'blank'} ] + Event::future.first(5).map { |x| { :img => x.image_url, :lines => x.poster_lines } }
        },
        { :type => 'footer' }
      ])
  end

  def EventPoster::generate1920x1080(event_id)
    @@image = MiniMagick::Image.open("printable/assets/1920x1080_bg.jpg")
    @@image.draw_elements([
      { :type     => 'event_bubble',
        :event_id => event_id,
        :x_offset => 40,
        :y_offset => 40,
        :width    => 1840,
        :height   => 1000,
        :ptscale  => 0.03,
        :ptscale2 => 0.025,
        :radius   => 940/10,
        :margin   => 1840*0.004,
        :wide     => true
      }
    ])
  end

  def EventPoster::generateFBEvent(event_id)
    @@image = MiniMagick::Image.open("printable/assets/fb_event_bg.jpg")
    @@image.draw_elements([
      { :type     => 'event_bubble', 
        :event_id => event_id,
        :x_offset => 20,
        :y_offset => 20,
        :width    => 1880,
        :margin   => 0,
        :height   => 1065,
        :ptscale  => 0.04,
        :ptscale2 => 0.043,
        :wide     => true
      }
    ])
  end
  
end