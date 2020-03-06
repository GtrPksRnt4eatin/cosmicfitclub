require 'date'
require 'fileutils'
require 'mini_magick'

module CampPoster

  def CampPoster::generate_all()
    FileUtils.mkdir_p "printable/results/class_schedules/class_sched_#{staff_id}"
    CampPoster::generate4x5(staff_id).save("class_schedules/class_sched_#{staff_id}/event_#{event_id}_4x5.jpg"); p "4x5 complete"
    CampPoster::generate4x6(staff_id).save("class_schedules/class_sched_#{staff_id}/event_#{event_id}_4x6.jpg"); p "4x6 complete"
    CampPoster::generate1080x1080(staff_id).save("class_schedules/class_sched_#{staff_id}/event_#{event_id}_1080x1080.jpg"); p "1x1 complete"
    CampPoster::generate1920x1080(staff_id).save("class_schedules/class_sched_#{staff_id}/event_#{event_id}_1920x1080.jpg"); p "HD complete"
    CampPoster::generate1080x1920(staff_id).save("class_schedules/class_sched_#{staff_id}/event_#{event_id}_1080x1920.jpg"); p "Story complete"
    CampPoster::generateFBEvent(staff_id).save("class_schedules/class_sched_#{staff_id}/event_#{event_id}_fbevent.jpg"); p "FB Event complete"
  end

  def CampPoster::generate_a4
    @@image = MiniMagick::Image.open("printable/assets/a4_bg.jpg")
    @@image.draw_elements([
      { :type     => 'logo',
        :x_offset => 20,
        :y_offset => 20,
        :width    => 650
      },
      { :type     => 'paragraph',
        :color    => '#FFFF00',
        :x_offset => 20,
        :y_offset => 400,
        :text     => "CIRCUS\r\nARTS\r\nPROGRAM"
      }
    ]).save('summercamp/summercamp_poster_a4.jpg')
  end

  def CampPoster::generate4x5(event_id)
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
        :ptscale  => 0.03
      }
    ])
  end
 
  def CampPoster::generate4x6(staff_id)
    staff = Staff[staff_id] or return
    @@image = MiniMagick::Image.open("printable/assets/4x6_bg.jpg")
    @@image.draw_elements([
      { :type     => 'logo',
        :x_offset => 50,
        :y_offset => 50,
        :width    => 1100
      },
      { :type     => 'image_bubble',
        :img      => staff.image[:original].url,
        :lines    => staff.footer_lines,
        :geometry => "1100x1100+50+550",
        :margin   => 5,
        :ptscale  => 0.06
      },
      { :type     => 'footer' }
    ]).save("staff/#{staff.name}_4x6.jpg")
  end

  def CampPoster::generate4x6quad(staff_ids)
    @@image = MiniMagick::Image.open("printable/assets/4x6_bg.jpg")
    @@image.draw_elements([
      { :type     => 'logo',
        :x_offset => 50,
        :y_offset => 50,
        :width    => 1100
      },
      { :type     => 'image_bubble',
        :img      => staff.image[:original].url,
        :lines    => staff.footer_lines,
        :geometry => "1100x1100+50+550",
        :margin   => 5,
        :ptscale  => 0.06
      },
      { :type     => 'image_bubble',
        :img      => staff.image[:original].url,
        :lines    => staff.footer_lines,
        :geometry => "1100x1100+50+550",
        :margin   => 5,
        :ptscale  => 0.06
      },
      { :type     => 'image_bubble',
        :img      => staff.image[:original].url,
        :lines    => staff.footer_lines,
        :geometry => "1100x1100+50+550",
        :margin   => 5,
        :ptscale  => 0.06
      },
      { :type     => 'image_bubble',
        :img      => staff.image[:original].url,
        :lines    => staff.footer_lines,
        :geometry => "1100x1100+50+550",
        :margin   => 5,
        :ptscale  => 0.06
      },
      { :type     => 'footer' }
    ])
  end

  def CampPoster::generate1080x1080(event_id)
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

  def CampPoster::generate1080x1920(event_id)
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

  def CampPoster::generate1920x1080(event_id)
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

  def CampPoster::generateFBEvent(event_id)
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