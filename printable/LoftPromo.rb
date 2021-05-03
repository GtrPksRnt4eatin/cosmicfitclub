module LoftPromo

  def LoftPromo::generate4x5()
    @@image = MiniMagick::Image.open("printable/assets/4x5_bg.jpg")
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
        :text     => "New In Person Offering!"
      },
      { :type     => 'image_bubble',
        :x_offset => 50,
        :y_offset => 260,
        :width    => 975,
        :height   => 975,
        :margin   => 5,
        :ptscale  => 0.05,
        :ptscale2 => 0.9,
        :img      => ClassDef[173].image_url,
        :lines    => ["Cosmic Greenpoint Loft", "Available for Small Groups", "Aerial Point, Spotting Belt, 18ft Ceilings", "sam@cosmicfitclub.com for bookings", "$12/person/hr"]
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
        :text     => "http://cosmicfitclub.com"
      }
    ])
  end

end