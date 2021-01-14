require 'date'
require 'fileutils'
require 'mini_magick'

module ClassPromo

  def ClassPromo::generate_for_bot(classdef)
    arr = []
    arr.push({ :img => ClassPromo::generate4x5({ :img=> classdef.image_url, :lines=>classdef.footer_lines_teachers }), :title => "#{classdef.name.truncate(12)}_fbpost"  })
    ##arr.push({ :img => ClassPromo::generate1080x1080(staff.id), :title => "#{staff.name.truncate(12)}_square"  })
    #arr.push({ :img => ClassPromo::generate1080x1920(staff.id), :title => "#{staff.name.truncate(12)}_story"   })
  end

  def ClassPromo::generate4x5(x)
    image = MiniMagick::Image.open("printable/assets/4x5_bg.jpg")
    image.draw_elements([
      { :type     => 'logo',
        :x_offset => 320,
        :y_offset => 20,
        :width    => 400
      },
      { :type     => "highlight_text",
        :x_offset => 0,
        :y_offset => 175,
        :ptsize   => 16,
        :strokewidth => 1,
        :kerning  => 5,
        :gravity  => "North",
        :fill     => "#E0E0E0",
        :stroke   => "#B0B0B0",
        :text     => "video.cosmicfitclub.com"
      },
      { :type     => 'image_bubble',
        :x_offset => 50,
        :y_offset => 260,
        :width    => 975,
        :height   => 975,
        :margin   => 5,
        :ptscale  => 0.05,
        :ptscale2 => 0.9,
        :img      => x[:img],
        :lines    => x[:lines]
      },
      { :type => 'box', 
        :width => 1080,
        :height => 100,
        :gravity => 'south',
        :y_offset => 1260,
        :color => '#00000055',
        :stroke => "#E0E0E0",
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
        :text     => "Live Video Fitness Classes Everyday!"
      }
    ])
  end
  
end