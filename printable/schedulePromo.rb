module SchedulePromo
  def SchedulePromo::generate_all()
    grouped = ClassdefSchedule.all.group_by { |x| { :class=> x.classdef.name, :teacher=>x.teachers.map(&:name).join(', ') } }
    list = grouped.map { |k,v| { :teacher => k[:teacher], :img => v[0].image_url, :lines => [k[:class], "w/ " + k[:teacher], v.map(&:simple_meeting_time_description).join(", ")] } } 
    list.each{ |x| SchedulePromo::generate4x5(x).save("vidpromos/schedules/#{x[:lines][0]} - #{x[:teacher]}.jpg") }
  end

  def SchedulePromo::generate4x5(x)
    image = MiniMagick::Image.open("printable/assets/4x5_bg.jpg")
    image.draw_elements([
      { :type     => 'logo',
        :x_offset => 340,
        :y_offset => 20,
        :width    => 400
      },
      { :type     => "highlight_text",
        :x_offset => 0,
        :y_offset => 175,
        :ptsize   => 18.5,
        :gravity  => "North",
        :text     => "video.cosmicfitclub.com"
      },
      { :type     => 'image_bubble',
        :x_offset => 50,
        :y_offset => 270,
        :width    => 980,
        :height   => 980,
        :margin   => 6,
        :ptscale  => 0.05,
        :ptscale2 => 0.9,
        :img      => x[:img],
        :lines    => x[:lines]
      },
      { :type     => "highlight_text",
        :x_offset => 0,
        :y_offset => 20,
        :ptsize   => 12.5,
        :gravity  => "South",
        :text     => "Live Video Fitness Classes Everyday!"
      }
    ])
  end
end






[1,4,7,9,13]