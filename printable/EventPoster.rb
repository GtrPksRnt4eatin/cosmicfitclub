require 'date'
require 'fileutils'
require 'mini_magick'

module EventPoster

  def EventPoster::generate_all(event_id)
    FileUtils.mkdir_p "printable/results/events/event_#{event_id}"
    EventPoster::generate4x5(event_id).save("events/event_#{event_id}/event_#{event_id}_4x5.jpg");             p "4x5 complete"
    EventPoster::generate4x6(event_id).save("events/event_#{event_id}/event_#{event_id}_4x6.jpg");             p "4x6 complete"
    EventPoster::generate1080x1080(event_id).save("events/event_#{event_id}/event_#{event_id}_1080x1080.jpg"); p "1x1 complete"
    EventPoster::generate1920x1080(event_id).save("events/event_#{event_id}/event_#{event_id}_1920x1080.jpg"); p "HD complete"
    EventPoster::generate1080x1920(event_id).save("events/event_#{event_id}/event_#{event_id}_1080x1920.jpg"); p "Story complete"
    EventPoster::generateFBEvent(event_id).save("events/event_#{event_id}/event_#{event_id}_fbevent.jpg");     p "FB Event complete"
  end

  def EventPoster::generate4x5(event_id)
    @@image = MiniMagick::Image.open("printable/assets/4x5_bg.jpg")
    @@image.draw_elements([
      { :type     => 'logo',
        :x_offset => 215,
        :y_offset => 30,
        :width    => 650
      },
      { :type     => 'event_bubble',
        :event_id => event_id,
        :x_offset => 40,
        :y_offset => 311,
        :width    => 1000,
        :margin   => 5,
        :ptscale  => 0.05
      }
    ])
  end
 
  def EventPoster::generate4x6(event_id)
    @@image = MiniMagick::Image.open("printable/assets/4x6_bg.jpg")
    @@image.draw_elements([
      { :type     => 'logo',
        :x_offset => 50,
        :y_offset => 50,
        :width    => 1100
      },
      { :type     => 'event_bubble',
        :event_id => event_id,
        :x_offset => 50,
        :y_offset => 550,
        :width    => 1100,
        :ptscale  => 0.05,
        :margin   => 5
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
        :margin   => 4,
        :ptscale  => 0.05
      }
    ])
  end

  def EventPoster::generate1080x1920(event_id)
    @@image = MiniMagick::Image.open("printable/assets/1080x1920_bg.jpg")
    @@image.draw_elements([
      { :type     => 'event_bubble',
        :event_id => event_id,
        :x_offset => 50,
        :y_offset => 470,
        :width    => 980,
        :ptscale  => 0.05
      }
    ])
  end

  def EventPoster::generate1920x1080(event_id)
    @@image = MiniMagick::Image.open("printable/assets/1920x1080_bg.jpg")
    @@image.draw_elements([
      { :type     => 'event_bubble',
        :event_id => event_id,
        :x_offset => 50,
        :y_offset => 40,
        :width    => 1000,
        :ptscale  => 0.05
      }
    ])
  end

  def EventPoster::generateFBEvent(event_id)
    @@image = MiniMagick::Image.open("printable/assets/fb_event_bg.jpg")
    @@image.draw_elements([
      { :type     => 'logo',
        :x_offset => 50,
        :y_offset => 50,
        :width    => 300
      },
      { :type     => 'event_bubble', 
        :event_id => event_id,
        :x_offset => 20,
        :y_offset => 20,
        :width    => 960,
        :margin   => 5,
        :height   => 484
      }
    ])
  end
  
end