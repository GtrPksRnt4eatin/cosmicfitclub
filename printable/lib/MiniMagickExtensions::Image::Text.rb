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
          i.fill opts['fill'] || Values::RedText
          i.font "shared/fonts/webfonts/329F99_3_0.ttf"
          i.density 300
          i.pointsize pointsize
          i.gravity opts['gravity'] || 'None'
          i.stroke  opts['stroke']  || "\#FFFFFFDD"
          i.strokewidth opts['strokewidth'] || pointsize*0.2
          i.draw "text #{x},#{y} \"#{text}\""
        end
      end

      def draw_paragraph(text,pointsize=18,x=0,y=0,gravity='None',color=Values::TextColor,spacing=0)
        self.combine_options do |i|
          i.fill color
          i.density 300
          i.pointsize "#{pointsize}"
          i.font "shared/fonts/webfonts/329F99_B_0.ttf"
          i.gravity "#{gravity}"
          i.interline_spacing spacing
          i.annotate "+#{x}+#{y}", text
          puts i.command
        end
      end

      def draw_footer(pointsize=nil, offset=0)
        pointsize ||= self.dimensions[0] * 0.0073
        line_height = pointsize * 300 / 72
        self.draw_box(0, height-(1.5*line_height)-offset, width, height)
        self.draw_text("21-36 44th Road L.I.C NY 11101  |  347-670-0019  |  cosmicfitclub.com", pointsize, 0, line_height*0.25+offset, "south")
      end

      def footer_lines(lines, ptsize=15, offset=20, uniform=false)
        ptsize = ptsize + 0.5
        line_height  = (ptsize/72*300)
        line_height2 = (ptsize/72*300) * 0.7
        y_offset = (lines.count-1) * (line_height2*1.2) + (line_height*1.4) + offset

        self.draw_box(0,self.dimensions[1]-y_offset,self.dimensions[0],self.dimensions[1], 0, 0, Values::MaskColor2 )
        y_offset = y_offset - 10 
        self.draw_text_header(lines[0],ptsize,0,y_offset-(line_height*1.2),"south")
        y_offset = y_offset - (line_height*1.4)

        ptsize = ptsize*0.6

        lines.drop(1).each_with_index do |line, i|
          self.draw_text_header(line,ptsize,0,y_offset-line_height2,"south") if uniform
          self.draw_text(line,ptsize,0,y_offset-line_height2,"south") unless uniform
          y_offset = y_offset - (line_height2 * 1.2)
        end
      end

    end

  end

end