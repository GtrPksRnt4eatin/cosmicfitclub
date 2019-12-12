module MiniMagickExtensions
  module Image
  	module Elements

      def draw_box(x_offset, y_offset, x, y, x_radius=0, y_radius=0, gravity='None', color=Values::MaskColor)
        self.combine_options do |i|
          i.fill color
          i.gravity "#{gravity}"
          i.draw "roundRectangle #{x_offset.to_i},#{y_offset.to_i} #{x_offset.to_i + x.to_i},#{y_offset.to_i + y.to_i} #{x_radius},#{y_radius}"
        end
      end

      def draw_logo(x,y,width,height,invert=false)
      	width  ||= (height * 2.8).to_i
      	height ||= (width  / 2.8).to_i
        p "invert is #{invert}"
      	logo = MiniMagick::Image.open("printable/assets/logo.png") unless invert
        logo = MiniMagick::Image.open("printable/assets/logo_blk.png") if invert
        result = self.composite(logo) do |c|
          c.compose "Over"
          c.geometry "#{width}x#{height}+#{x}+#{y}"
        end
        self.clone_img(result)
        self
      end

      def draw_footer(pointsize, offset=0)
        line_height = pointsize * 300 / 72
        self.draw_box(0, height-(1.5*line_height)-offset, width, height)
        self.draw_text("21-36 44th Road L.I.C NY 11101  |  347-670-0019  |  cosmicfitclub.com", pointsize, 0, line_height*0.25+offset, "south")
      end

      def draw_text(text,pointsize=18,x=0,y=0,gravity='None')
        self.combine_options do |i|
          i.fill Values::TextColor
          i.density 300
          i.pointsize "#{pointsize}"
          i.font "shared/fonts/webfonts/329F99_B_0.ttf"
          i.gravity "#{gravity}"
          i.draw "text #{x},#{y} \"#{text}\""
        end
      end

      def draw_text_header(text,pointsize=18,x=0,y=0,gravity='None')
        self.combine_options do |i|
          i.fill Values::TextColor
          i.density 300
          i.pointsize "#{pointsize}"
          i.font "shared/fonts/webfonts/329F99_3_0.ttf"
          i.gravity "#{gravity}"
          i.draw "text #{x},#{y} \"#{text}\""
        end
      end


      def draw_highlight_text(text,pointsize,x,y,gravity,fill=Values::RedText,stroke="\#FFFFFFDD",strokewidth=3)
        self.combine_options do |i|
          i.fill fill
          i.font "shared/fonts/webfonts/329F99_3_0.ttf"
          i.density 300
          i.pointsize pointsize
          i.gravity gravity
          i.stroke stroke
          i.strokewidth strokewidth
          i.draw "text #{x},#{y} \"#{text}\""
        end
      end

      def draw_iphone_bubble(cls_id, x, y, size)
        
        cls = ClassDef[cls_id] or return   
        img  = MiniMagick::Image.open(cls.image[:original].url)
        img.resize "#{size}x#{size}!"
        
        ptsize = (size * 0.05) / 300 * 72
        lines = [cls.name] + cls.meeting_times
        #img.footer_lines(lines,ptsize)

        img.draw_box(0,size.to_i*0.78,size.to_i,size.to_i*0.22)
        img.draw_text_header(cls.name,ptsize,0,size*0.12,"south")
        img.draw_text(cls.meeting_times.join(", "),ptsize,0,size* 0.04,"south")      

        img.mask_edges
        
        margin = size*0.005          # Border Around Image
        self.draw_box(x-margin, y-margin, size+margin*2, size+margin*2, size/10, size/10)
        
        result = self.composite(img) do |c|
          c.compose "Over"
          c.geometry "#{size}x#{size}+#{x}+#{y}"
        end
        
        self.clone_img(result)
      end

      def draw_iphone_bubble2(cls_id, x, y, width, height=nil)
        height ||= width
        
        cls = ClassDef[cls_id] or return   
        img  = MiniMagick::Image.open(cls.image[:original].url)
        img.resize "#{width}x#{height}!"
        
        ptsize = (width * 0.05) / 300 * 72
        lines = [cls.name] + cls.meeting_times_with_staff
        img.footer_lines(lines,ptsize)

        img.mask_edges
        
        margin = width*0.005          # Border Around Image
        self.draw_box(x-margin, y-margin, width+margin*2, height+margin*2, width/10, height/10, 'None', Values::WhiteGlow)
        
        result = self.composite(img) do |c|
          c.compose "Over"
          c.geometry "#{width}x#{height}+#{x}+#{y}"
        end
        
        self.clone_img(result)
      end

      def overlay(img, width, height, x, y)
        result = self.composite(img) do |c|
          c.compose "Over"
          c.geometry "#{width}x#{height}+#{x}+#{y}"
        end
        self.clone_img(result)
      end

      def to_bubble(lines, ptsize=nil)
        ptsize ||= (self.dimensions[0] * 0.05) / 300 * 72
        self.footer_lines(lines,ptsize,20)
        self.mask_edges
      end

      def bubble_shadow(width,height,x,y,margin=nil,radius=nil,color=Values::WhiteGlow)
        margin ||= width*0.05
        radius ||= width/10
        self.draw_box(x-margin, y-margin, width+margin*2, height+margin*2, radius, radius, 'None', Values::WhiteGlow)
      end

      def footer_lines(lines, ptsize=15, offset=20)
        ptsize = ptsize + 0.5
        line_height  = (ptsize/72*300)
        line_height2 = (ptsize/72*300)*0.8
        y_offset = (lines.count-1) * (line_height2*1.2) + (line_height*1.4) + offset

        self.draw_box(0,self.dimensions[1]-y_offset,self.dimensions[0],self.dimensions[1], 0, 0, 'None', Values::MaskColor2 )
        y_offset = y_offset - 10 
        self.draw_text_header(lines[0],ptsize,0,y_offset-(line_height*1.2),"south")
        y_offset = y_offset - (line_height*1.4)

        ptsize = ptsize*0.8

        lines.drop(1).each_with_index do |line, i|
          self.draw_text(line,ptsize,0,y_offset-line_height2,"south")
          y_offset = y_offset - (line_height2 * 1.2)
        end
      end

      def mask_edges
        mask = MiniMagick::Image.open("printable/assets/mask.png")
        mask.resize "#{self.dimensions[0]}x#{self.dimensions[1]}!"
        result = mask.composite(self,'png') do |c|
          c.compose "src-in"
          c.geometry "+0+0"
        end
        self.clone_img(result)
      end

    end

    module Values
      MaskColor   = "\#00000099"
      MaskColor2  = "\#000000AA"
      TextColor   = "\#FFFFFFFF"
      WhiteGlow   = "\#FFFFFF66"
      RedText     = "\#FF0000FF"
    end

    module Loading

      def clone_img(other)
        @path = other.path
        @info.clear
        self       
      end

      def save(filename)
        self.write("printable/results/#{filename}")
      end

    end

  end

end

MiniMagick::Image.include MiniMagickExtensions::Image::Loading
MiniMagick::Image.include MiniMagickExtensions::Image::Elements