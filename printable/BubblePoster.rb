require 'date'
require 'mini_magick'

module BubblePoster

  def BubblePoster::get_bubble_data(data)
    val = case data[0]
    when :class
      cls = ClassDef[data[1]] or return
      { :img => cls.image.url, :lines => cls.footer_lines }
    when :event
      evt = Event[data[1]] or return
      { :img => evt.image.url, :lines => evt.poster_lines }
    when :staff
      stf = Staff[data[1]] or return
      { :img => stf.image(:original).url, :lines => stf.footer_lines }
    when :sched
      sch = ClassdefSchedule[data[1]] or return
      { :img => sch.thumb_url, :lines => sch.poster_lines }
    end
    val
  end
 
  def BubblePoster::generate_4x6(data=[[:class,40],[:class,36],[:class,32],[:class,42]],opts={})
    @@image = MiniMagick::Image.open("printable/assets/4x6_bg.jpg")
    @@image.draw_elements([
        { :type     => 'bubble_shadow',
          :width    => 525,
          :height   => 516,
          :x_offset => 50,
          :y_offset => 50,
          :margin   => 900*0.008
        },
        { :type      => 'box',
          :x_offset  => 50,
          :y_offset  => 50,
          :width     => 525,
          :height    => 516,
          :radius    => 45,
        },
        { :type     => 'logo',
          :x_offset => 75,
          :y_offset => 160,
          :width    => 480
        },
        { :type        => 'highlight_text',
          :text        => 'Weekly Classes!',
          :ptsize      => 12.5,
          :x_offset    => 95,
          :y_offset    => 420,
          :fill        => "\#BBBBFFFF",
          :stroke      => "\#DDDDFFDD",
          :strokewidth => 1
        },

      { :type     => 'img_array',
        :x_offset => 0,
        :y_offset => 0,
        :width    => 1200,
        :height   => 1760,
        :margin_x => 50,
        :margin_y => 50,
        :rowsize  => 2,
        :ptscale  => opts[:ptscale]  || 0.045,
        :ptscale2 => opts[:ptscale2] || 1,
        :images   => [ { :img => 'blank'} ] + data.map { |x| BubblePoster::get_bubble_data(x) }
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
        :y_offset => opts[:offset] || 0,
        :width    => opts[:width] || 2411,
        :height   => opts[:height] || 2411,
        :margin   => opts[:margin] || 75,
        :rowsize  => opts[:rowsize] || 3,
        :ptscale  => opts[:ptscale]  || 0.075,
        :ptscale2 => opts[:ptscale2] || 0.9,
        :images   => data.map { |x| BubblePoster::get_bubble_data(x) }
      },
      { :type => 'footer' }
    ])

    @@image.write("printable/results/a4_classes.jpg")

    @@image

  end
  
end
