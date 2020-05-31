require 'date'
require 'mini_magick'

module BubblePoster

  def BubblePoster::get_bubble_data(data)
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
    when :sched
      sch = ClassdefSchedule[data[1]] or return
      { :img => sch.thumb_url, :lines => sch.poster_lines }
    end
    val
  end
 
  def BubblePoster::generate_4x6(data=[[:class,40],[:class,36],[:class,32],[:class,42]],opts={})
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

  def BubblePoster::generate_a4(data=[[:class,40],[:class,36],[:class,32],[:class,42]],opts={})
    @@image = MiniMagick::Image.open("printable/assets/a4_bg.jpg")
    @@image.draw_elements([
      { :type     => 'img_array',
        :x_offset => 0,
        :y_offset => 0,
        :width    => 2411,
        :height   => 2411,
        :margin   => 75,
        :rowsize  => 3,
        :ptscale  => opts[:ptscale]  || 0.075,
        :ptscale2 => opts[:ptscale2] || 0.9,
        :images   => data.map { |x| BubblePoster::get_bubble_data(x) }
      },
      { :type        => 'highlight_text',
        :text        => 'First Class Free! Come In Today!',
        :ptsize      => 30,
        :x_offset    => 0,
        :y_offset    => 140,
        :gravity     => 'South',
        :strokewidth => 3 
      },
      { :type => 'footer' }
    ])

    @@image.write("printable/results/a4_classes.jpg")

    @@image

  end
  
end