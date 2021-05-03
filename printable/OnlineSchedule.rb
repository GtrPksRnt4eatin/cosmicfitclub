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