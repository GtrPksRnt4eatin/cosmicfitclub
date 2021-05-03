module OnlineSchedule

  TILES = [ [:class,74], [] ]

  def OnlineSchedule::get_tiles
  
  end  

	def OnlineSchedule::generate_all

	end 

	def OnlineSchedule::generate_instagram_story

	end

	def OnlineSchedule::generate_fb_post

	end

	def OnlineSchedule::generate4x5()
    @@image = MiniMagick::Image.open("printable/assets/4x5_bg.jpg")
    bubbles = ClassDef.list_active_and_current.select { |c| c.location_id == 3 }
    bubbles.map! { |c| { :img => c.thumbnail_image, :lines => c.footer_lines_teachers } }
    bubbles << { :img => "printable/assets/cat2.jpg", :lines => ["Donut"] }
    @@image.draw_elements([
      { :type => 'box', 
        :width => 1079,
        :height => 220,
        :gravity => 'north',
        :y_offset => 0,
        :color => '#00000055',
        :stroke => "#E0E0E0",
      },
      { :type     => 'logo',
        :x_offset => 380,
        :y_offset => 20,
        :width    => 320
      },
      { :type     => "highlight_text",
        :x_offset => 0,
        :y_offset => 150,
        :ptsize   => 13,
        :strokewidth => 1,
        :stroke   => "#FFFFFFDD",
        :fill    => "#FFFFFFDD",
        :gravity  => "North",
        :kerning  => 5,
        :text     => "video.cosmicfitclub.com"
      },
      { :type     => 'img_array',
        :x_offset => 0,
        :y_offset => 205,
        :width    => 1080,
        :height   => 1080,
        :margin   => 40,
        :ptscale  => 0.055,
        :ptscale2 => 0.9,
        :rowsize  => 3,
        :images   => bubbles
      },
      { :type => 'box', 
        :width => 1079,
        :height => 90,
        :gravity => 'south',
        :y_offset => 1260,
        :color => '#00000055',
        :stroke => "#E0E0E0",
      },
      { :type     => "highlight_text",
        :x_offset => 0,
        :y_offset => 20,
        :ptsize   => 12,
        :strokewidth => 1,
        :stroke   => "#FFFFFFDD",
        :fill    => "#FFFFFFDD",
        :gravity  => "South",
        :kerning  => 5,
        :text     => "Online Video Classes Every Day"
      }
    ])
  end

  def OnlineSchedule::generate4x5staff()
    @@image = MiniMagick::Image.open("printable/assets/4x5_bg.jpg")
    @@image.draw_elements([
      { :type     => 'logo',
        :x_offset => 380,
        :y_offset => 20,
        :width    => 320
      },
      { :type     => "highlight_text",
        :x_offset => 0,
        :y_offset => 145,
        :ptsize   => 13.5,
        :gravity  => "North",
        :text     => "video.cosmicfitclub.com"
      },
      { :type     => 'img_array',
        :x_offset => 0,
        :y_offset => 200,
        :width    => 1080,
        :height   => 1080,
        :margin   => 40,
        :ptscale  => 0.05,
        :ptscale2 => 0.9,
        :rowsize  => 1,
        :images   => Staff..select{ |s| s.location_id == 1 }.map { |s|
          { :img   => s.thumbnail_image,
            :lines => s.footer_lines_teachers
          }
        }
      },
    ])
  end

  def OnlineSchedule::generate_options()
    @@image = MiniMagick::Image.open("printable/assets/4x5_bg.jpg")
    @@image.draw_elements([
      { :type     => 'logo',
        :x_offset => 380,
        :y_offset => 20,
        :width    => 320
      },
      { :type     => "highlight_text",
        :x_offset => 0,
        :y_offset => 145,
        :ptsize   => 13.5,
        :gravity  => "North",
        :text     => "Three Great Options"
      },

      { :type     => 'img_array',
        :x_offset => 0,
        :y_offset => 200,
        :width    => 1080,
        :height   => 1080,
        :margin   => 40,
        :ptscale  => 0.05,
        :ptscale2 => 0.9,
        :rowsize  => 3,
        :images   => ClassDef.list_active_and_current.map { |s|
          { :img   => s.thumbnail_image,
            :lines => s.footer_lines_teachers
          }
        }
      },
    ])
  end

end