module MiniMagickExtensions
 
  module Image

    module Elements

      def draw_box(x_offset, y_offset, x, y, x_radius=0, y_radius=0, color=Values::MaskColor)	
        self.combine_options do |i|	
          i.fill color	
          i.draw "roundRectangle #{x_offset.to_i},#{y_offset.to_i} #{x_offset.to_i + x.to_i},#{y_offset.to_i + y.to_i} #{x_radius},#{y_radius}"	
        end	
      end	

      def draw_logo(x,y,width,height=nil,invert=false)	
      	width  ||= (height * 2.8).to_i	
      	height ||= (width  / 2.8).to_i	
      	logo = MiniMagick::Image.open("printable/assets/logo.png") unless invert	
        logo = MiniMagick::Image.open("printable/assets/logo_blk.png") if invert	
        self.overlay(logo, width, height, x, y)	
      end

    end

  end

end