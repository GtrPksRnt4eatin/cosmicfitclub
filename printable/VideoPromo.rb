module VideoPromo2

    def VideoPromo2::generate4x5(event_id)
      @@image = MiniMagick::Image.open("printable/assets/4x5_bg.jpg")
      @@image.draw_elements([
        { :type     => 'logo',
          :x_offset => 280,
          :y_offset => 30,
          :width    => 520
        },
        { :type => 'box', 
          :width => 1079,
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
      #@@image.bubble_shadow({
      #  :x_offset => 50,
      #  :y_offset => 260,
      #  :width    => 975 + 975 * 0.006,
      #  :height   => 975 + 975 * 0.006
      #})
      @@image.draw_video_mask({
        :x_offset => 50,
        :y_offset => 260,
        :width    => 975,
        :height   => 975
      })
      #@@image.draw_event_bubble(
      #{
      #  :event_id => event_id,
      #  :video => true,
      #  :x_offset => 50,
      #  :y_offset => 260,
      #  :width    => 975,
      #  :margin   => 5,
      #  :ptscale  => 0.05,
      #  :ptscale2 => 0.043
      #})

    end
  
end