module MiniMagickExtensions
  module Image
  	module Elements

      def draw_box(x_offset, y_offset, x, y, x_radius=0, y_radius=0)
        self.combine_options do |i|
          i.fill Values::MaskColor
          i.draw "roundRectangle #{x_offset},#{y_offset} #{x_offset + x},#{y_offset + y} #{x_radius},#{y_radius}"
        end
      end

      def draw_logo(x,y,width,height)
      	width  ||= (height * 2.8).to_i
      	height ||= (width  / 2.8).to_i
      	logo = MiniMagick::Image.open("printable/assets/logo.png")
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

        #self.combine_options do |i|
        #  i.fill Values::MaskColor
        #  i.draw "rectangle 0,#{self.height-(line_height * 1.5)} #{self.width},#{self.height}"
        #end


        #self.combine_options do |i|
        #  i.fill Values::TextColor
        #  i.density 300
        #  i.pointsize "#{pointsize}"
        #  i.font "shared/fonts/webfonts/329F99_B_0.ttf"
        #  i.gravity "South"
        #  i.draw "text 0,#{line_height * 0.25} \"21-36 44th Road L.I.C NY 11101  |  347-670-0019  |  cosmicfitclub.com\""
        #end
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

      def draw_iphone_bubble(img_path, text, x, y, size)
        img  = MiniMagick::Image.open(img_path)
        mask = MiniMagick::Image.open("printable/assets/mask.png")
        img.resize "#{size}x#{size}!"
        img.draw_box(0,size*0.8,size,size*0.2)
        img.draw_text_header(text,27,0,40,"south")
        img = mask.composite(img,'png') do |c|
          c.compose "src-in"
          c.geometry "+0+0"
        end
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

    end

  end

end

MiniMagick::Image.include MiniMagickExtensions::Image::Loading
MiniMagick::Image.include MiniMagickExtensions::Image::Elements