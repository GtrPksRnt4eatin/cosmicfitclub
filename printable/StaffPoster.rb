require 'date'
require 'fileutils'
require 'mini_magick'

module StaffPoster

  def StaffPoster::generate_for_bot(staff)
    arr = []
    arr.push({ :img => StaffPoster::generate4x5(staff.id),       :title => "#{staff.name.truncate(12)}_fbpost"  })
    arr.push({ :img => StaffPoster::generate1080x1080(staff.id), :title => "#{staff.name.truncate(12)}_square"  })
    arr.push({ :img => StaffPoster::generate1080x1920(staff.id), :title => "#{staff.name.truncate(12)}_story"   })
  end

  def StaffPoster::generate_all(staff_id)
    FileUtils.mkdir_p "printable/results/class_schedules/class_sched_#{staff_id}"
    StaffPoster::generate4x5(staff_id).save("class_schedules/class_sched_#{staff_id}/event_#{event_id}_4x5.jpg"); p "4x5 complete"
    StaffPoster::generate4x6(staff_id).save("class_schedules/class_sched_#{staff_id}/event_#{event_id}_4x6.jpg"); p "4x6 complete"
    StaffPoster::generate1080x1080(staff_id).save("class_schedules/class_sched_#{staff_id}/event_#{event_id}_1080x1080.jpg"); p "1x1 complete"
    StaffPoster::generate1920x1080(staff_id).save("class_schedules/class_sched_#{staff_id}/event_#{event_id}_1920x1080.jpg"); p "HD complete"
    StaffPoster::generate1080x1920(staff_id).save("class_schedules/class_sched_#{staff_id}/event_#{event_id}_1080x1920.jpg"); p "Story complete"
    StaffPoster::generateFBEvent(staff_id).save("class_schedules/class_sched_#{staff_id}/event_#{event_id}_fbevent.jpg"); p "FB Event complete"
  end

  def StaffPoster::generate4x5(event_id)
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
 
  def StaffPoster::generate4x6(staff_id)
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

  def StaffPoster::generate4x6quad(staff_ids)
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

  def StaffPoster::generate1080x1080(event_id)
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

  def StaffPoster::generate1080x1920(event_id)
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

  def StaffPoster::generate1920x1080(event_id)
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

  def StaffPoster::generateFBEvent(event_id)
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