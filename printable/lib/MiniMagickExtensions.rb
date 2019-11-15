module MiniMagickExtensions
  module Image
  	module Elements

      def draw_box(x_offset, y_offset, x, y, x_radius=0, y_radius=0, gravity='None')
        self.combine_options do |i|
          i.fill Values::MaskColor
          i.gravity "#{gravity}"
          i.draw "roundRectangle #{x_offset},#{y_offset} #{x_offset + x},#{y_offset + y} #{x_radius},#{y_radius}"
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
      end

      def draw_footer(pointsize)
        line_height = pointsize * 300 / 72
        self.draw_box(0, height-(1.5*line_height), width, height)
        self.draw_text("21-36 44th Road L.I.C NY 11101  |  347-670-0019  |  cosmicfitclub.com", pointsize, 0, line_height*0.25, "south")
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

      def draw_iphone_bubble(cls_id, x, y, size)
        cls = ClassDef[cls_id] or return   
        img  = MiniMagick::Image.open(cls.image[:original].url)
        mask = MiniMagick::Image.open("printable/assets/mask.png")
        mask.resize "#{size}x#{size}!"
        img.resize "#{size}x#{size}!"
        ptsize = (size * 0.05) / 300 * 72
        img.draw_box(0,size.to_i*0.78,size.to_i,size.to_i*0.22)
        img.draw_text_header(cls.name,ptsize,0,size*0.12,"south")
        img.draw_text(cls.meeting_times.join(", "),ptsize,0,size* 0.04,"south")
        img = mask.composite(img,'png') do |c|
          c.compose "src-in"
          c.geometry "+0+0"
        end
        margin = size*0.005
        self.draw_box(x-margin, y-margin, size+margin*2, size+margin*2, size/10, size/10)
        self.composite(img) do |c|
          c.compose "Over"
          c.geometry "#{size}x#{size}+#{x}+#{y}"
        end
      end

      def get_type_metrics(size, font, text)
      end

    end

    module Values
      MaskColor = "\#00000099"
      TextColor = "\#FFFFFFFF"
    end

    module Loading

      def clone_img(other)
        @path = other.path
        @info.clear        
      end

      def save(filename)
        self.write("printable/results/#{filename}")
      end

    end

  end

end

MiniMagick::Image.include MiniMagickExtensions::Image::Loading
MiniMagick::Image.include MiniMagickExtensions::Image::Elements