module MiniMagickExtensions
 
  module Image

    module Text

      def draw_text_header(text,pointsize=18,x=0,y=0,gravity='None',color=Values::TextColor)
        self.combine_options do |i|
          i.fill color
          i.density 300
          i.pointsize "#{pointsize}"
          i.font "shared/fonts/webfonts/329F99_3_0.ttf"
          i.gravity "#{gravity}"
          i.draw "text #{x},#{y} \"#{text}\""
        end
      end

      def draw_text(text,pointsize=18,x=0,y=0,gravity='None',color=Values::TextColor)
        self.combine_options do |i|
          i.fill color
          i.density 300
          i.pointsize "#{pointsize}"
          i.font "shared/fonts/webfonts/329F99_B_0.ttf"
          i.gravity "#{gravity}"
          i.draw "text #{x},#{y} \"#{text}\""
        end
      end

      def draw_highlight_text(text,pointsize,x,y,opts={})
        self.combine_options do |i|
          i.fill opts[:fill] || Values::RedText
          i.font "shared/fonts/webfonts/329F99_3_0.ttf"
          i.density 300
          i.pointsize pointsize
          i.gravity opts[:gravity] || 'None'
          i.stroke  opts[:stroke]  || "\#FFFFFFDD"
          i.strokewidth opts[:strokewidth] || pointsize*0.2
          i.draw "text #{x},#{y} \"#{text}\""
        end
      end

      def draw_paragraph(text,pointsize=18,x=0,y=0,gravity='None',color=Values::TextColor,spacing=0)
        opts[:text]      ||= ""
        opts[:pointsize] ||= 18
        opts[:x_offset]  ||= 0
        opts[:y_offset]  ||= 0
        opts[:gravity]   ||= 'None'
        opts[:font]      ||= "shared/fonts/webfonts/329F99_B_0.ttf"
        opts[:color]     ||= Values::TextColor
        opts[:spacing]   ||= 0
        self.combine_options do |i|
          i.density           300
          i.fill              opts[:color]
          i.pointsize         opts[:pointsize]
          i.font              opts[:font]
          i.gravity           opts[:gravity]
          i.interline_spacing opts[:spacing]
          i.annotate "+#{opts[:x_offset]}+#{opts[:y_offset]}", opts[:text]
          puts i.command
        end
      end

      def draw_footer(pointsize=nil, offset=0)
        pointsize ||= self.dimensions[0] * 0.0073
        line_height = pointsize * 300 / 72
        self.draw_box({
          :x_offset => 0,
          :y_offset => height-(1.5*line_height)-offset,
          :width    => width, 
          :height   => height
        })
        self.draw_text("21-36 44th Road L.I.C NY 11101  |  347-670-0019  |  cosmicfitclub.com", pointsize, 0, line_height*0.25+offset, "south")
      end

      def footer_lines(opts)
        opts[:lines]   ||= []
        opts[:ptsize]  ||= 15
        opts[:offset]  ||= 20
        opts[:uniform] ||= false
        opts[:ptsize2] ||= opts[:ptsize] * 0.6

        line_count   = opts[:lines].count-1
        line_height  = (opts[:ptsize]  / 72 * 300) * 1.1
        line_height2 = (opts[:ptsize2] / 72 * 300) * 1.1

        y_offset = opts[:offset] + line_height +  line_height2 * line_count

        self.draw_box({
          :x_offset => 0,
          :y_offset => self.dimensions[1]-y_offset,
          :width    => self.dimensions[0],
          :height   => self.dimensions[1],
          :radius   => 0,
          :color    => Values::MaskColor2 
        })
        y_offset = y_offset - 10 
        self.draw_text_header(opts[:lines][0],opts[:ptsize],0,y_offset-line_height,"south")
        y_offset = y_offset - line_height

        opts[:lines].drop(1).each_with_index do |line, i|
          self.draw_text_header(line,opts[:ptsize2],0,y_offset-line_height2,"south") if opts[:uniform]
          self.draw_text(line,opts[:ptsize2],0,y_offset-line_height2,"south")    unless opts[:uniform]
          y_offset = y_offset - line_height2
        end
      end

    end

  end

end