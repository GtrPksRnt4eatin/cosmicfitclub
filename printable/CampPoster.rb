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
      { :type     => 'box',
        :width    => 1228,
        :height   => 3350,
        :x_offset => 40,
        :y_offset => 40,
        :radius   => 120
      },
      { :type     => 'logo',
        :x_offset => 70,
        :y_offset => 60,
        :width    => 1150
      },
      { :type     => 'paragraph',
        :color    => '#FFFF00',
        :x_offset => 70,
        :y_offset => 750,
        :ptsize   => 58,
        :font     => "shared/fonts/webfonts/329F99_3_0.ttf",
        :text     => "CIRCUS\r\nARTS\r\nPROGRAM"
      },
      { :type     => 'paragraph',
        :color    => '#FFFFFF',
        :x_offset => 70,
        :y_offset => 1375,
        :spacing  => 12,
        :text     => %{ 
          This summer, children from ages
          7-14 will discover the exciting 
          world of circus arts: learn how to
          fly high on aerial silks, walk the
          tight wire, juggle, clown, 
          unicycle, build human pyramids
          and much more!
        }.gsub(/ +/, ' ').gsub(/^ /,'')
      },
      { :type     => 'paragraph',
        :color    => '#FFFFFF',
        :x_offset => 70,
        :y_offset => 2070,
        :spacing  => 12,
        :text     => %{ 
          Offered 9am-3pm in three
          2-week sessions culminating in a
          student performance!
        }.gsub(/ +/, ' ').gsub(/^ /,'')
      },
      { :type     => 'paragraph',
        :color    => '#FFFFFF',
        :x_offset => 70,
        :y_offset => 2420,
        :spacing  => 12,
        :text     => %{ 
          Early Bird Pricing until 4/30
          Sibling & Multi-Session discounts
          available online.
        }.gsub(/ +/, ' ').gsub(/^ /,'')
      },
      { :type     => 'paragraph',
        :color    => '#FFFF00',
        :x_offset => -560,
        :y_offset => 2700,
        :ptsize   => 21,
        :gravity  => 'North',
        :spacing  => '20',
        :font     => "shared/fonts/webfonts/329F99_3_0.ttf",
        :text     => %{ 
          JUNE 29 - JULY 10, 2020
          JULY 13 - JULY 24, 2020
          JULY 27 - AUGUST 7, 2020
        }.gsub(/ +/, ' ').gsub(/^ /,'')
      },
      { :type     => 'paragraph',
        :color    => '#FFFFFF',
        :x_offset => -560,
        :y_offset => 3100,
        :ptsize   => 16,
        :gravity  => 'North',
        :spacing  => '20',
        :text     => %{ 
          For more information, visit
          https://cosmicfitclub.com/kidscircus
        }.gsub(/ +/, ' ').gsub(/^ /,'')
      },
      { :type     => 'img_array',
        :width    => 1143,
        :height   => 3350,
        :x_offset => 1268,
        :margin   => 40,
        :images   => [
          { :img   => 'printable/assets/summercamp/kidscamp1.jpg', :lines => [] },
          { :img   => 'printable/assets/summercamp/kidscamp2.jpg', :lines => [] },
          { :img   => 'printable/assets/summercamp/kidscamp3.png', :lines => [] }
        ]
      },
      { :type => 'footer' }
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
        :img      => staff.image(:original).url,
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
        :img      => staff.image(:original).url,
        :lines    => staff.footer_lines,
        :geometry => "1100x1100+50+550",
        :margin   => 5,
        :ptscale  => 0.06
      },
      { :type     => 'image_bubble',
        :img      => staff.image(:original).url,
        :lines    => staff.footer_lines,
        :geometry => "1100x1100+50+550",
        :margin   => 5,
        :ptscale  => 0.06
      },
      { :type     => 'image_bubble',
        :img      => staff.image(:original).url,
        :lines    => staff.footer_lines,
        :geometry => "1100x1100+50+550",
        :margin   => 5,
        :ptscale  => 0.06
      },
      { :type     => 'image_bubble',
        :img      => staff.image(:original).url,
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