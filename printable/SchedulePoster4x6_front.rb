require 'date'
require 'mini_magick'

module SchedulePoster4x6_front

  def SchedulePoster4x6_front::get_bubble_data(data)
    val = case data[0]
    when :class
      cls = ClassDef[data[1]] or return
      { :img => cls.image[:original].url, :lines => cls.footer_lines }
    when :event
      evt = Event[data[1]] or return
      { :img => evt.image[:original].url, :lines => evt.poster_lines }
    when :staff
      stf = Staff[data[1]] or return
      { :img => stf.image[:original].url, :lines => stf.footer_lines }
    end
    p val
    val
  end
 
  def SchedulePoster4x6_front::generate(data=[[:class,40],[:class,36],[:class,32],[:class,42]],opts={})
    @@image = MiniMagick::Image.open("printable/assets/4x6_bg.jpg")
    @@image.draw_elements([
      { :type     => 'logo',
        :x_offset => 75,
        :y_offset => 75,
        :width    => 1050
      },
      { :type     => 'img_array',
        :x_offset => 0,
        :y_offset => 447,
        :width    => 1200,
        :margin   => 75,
        :rowsize  => 2,
        :ptscale  => opts[:ptscale]  || 0.083,
        :ptscale2 => opts[:ptscale2] || 0.9,
        :images   => data.map { |x| SchedulePoster4x6_front::get_bubble_data(x) }
      },
      { :type        => 'highlight_text',
        :text        => 'First Class Free! Come In Today!',
        :ptsize      => 17,
        :x_offset    => 0,
        :y_offset    => 110,
        :gravity     => 'South',
        :strokewidth => 3 
      },
      { :type => 'footer' }
    ])

    @@image.write("printable/results/4x6_front.jpg")

    @@image

  end
  
end