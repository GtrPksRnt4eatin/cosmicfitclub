module MiniMagickExtensions
 
  module Image

    module Elements

      def draw_box(opts)
        opts[:radius]   ||= 0
        opts[:x_radius] ||= opts[:radius]
        opts[:y_radius] ||= opts[:x_radius]
        opts[:color]    ||= Values::MaskColor
        opts[:x_offset] ||= 0
        opts[:y_offset] ||= 0
        self.combine_options do |i|	
          i.fill opts[:color]
          i.draw "roundRectangle #{opts[:x_offset].to_i},#{opts[:y_offset].to_i} #{opts[:x_offset].to_i + opts[:width].to_i},#{opts[:y_offset].to_i + opts[:height].to_i} #{opts[:x_radius]},#{opts[:y_radius]}"	
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