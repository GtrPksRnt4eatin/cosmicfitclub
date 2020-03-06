module MiniMagickExtensions
 
  module Image

    module Bubbles

      def build_mask(opts)
        p opts[:radius]
        opts[:radius] ||= [opts[:width],opts[:height]].min/10
        MiniMagick::Tool::Convert.new do |i|
          i.size "#{opts[:width]}x#{opts[:height]}"
          i.gravity "center"
          i.xc "transparent"
          i << 'printable/assets/tmp/mask.png'
        end
        img = MiniMagick::Image.open("printable/assets/tmp/mask.png")
        p img
        p opts[:radius]
        img.draw_box({
          :width => opts[:width],
          :height => opts[:height],
          :color  => 'White',
          :radius => opts[:radius]
        })
      end

      def to_bubble(lines=nil, ptscale=0.05, ptscale2=0.74)
        ptsize  = self.dimensions[0].to_f / 300 * 72 * ptscale 
        ptsize2 = ptsize * ptscale2
        self.footer_lines({ :lines=>lines, :ptsize=>ptsize, :ptsize2 => ptsize2, :offset=>20 }) unless lines.nil?
        self.mask_edges
      end

      def draw_bubble(path,lines,geometry,opts={})
        geo = /(?<width>\d+)x(?<height>\d+)\+(?<x>\d+)\+(?<y>\d+)/.match(geometry)
        @img = MiniMagick::Image.open(path)
        @img.resize_with_crop(geo[:width].to_i,geo[:height].to_i,{ :geometry => :south })
        @img.to_bubble(lines, opts[:ptscale] || 0.07, opts[:ptscale2] || 0.74 )
        self.bubble_shadow({
          :width    => geo[:width].to_i,
          :height   => geo[:height].to_i,
          :x_offset => geo[:x].to_i,
          :y_offset => geo[:y].to_i,
          :margin   => opts[:margin]
        })
        self.overlay(@img,geo[:width].to_i,geo[:height].to_i,geo[:x].to_i,geo[:y].to_i)
      end

      def bubble_shadow(opts)
        opts[:width]    ||= 500
        opts[:height]   ||= opts[:width]
        opts[:x_offset] ||= 0
        opts[:y_offset] ||= 0
        opts[:color]    ||= Values::WhiteGlow
        opts[:margin]   ||= opts[:width] * 0.01
        opts[:radius]   ||= opts[:width] / 10
        p opts[:radius]
        self.draw_box({
          :x_offset => opts[:x_offset] - opts[:margin], 
          :y_offset => opts[:y_offset] - opts[:margin], 
          :width    => opts[:width]    + opts[:margin] * 2,
          :height   => opts[:height]   + opts[:margin] * 2,
          :radius   => opts[:radius], 
          :color    => opts[:color]
        })
      end

      def draw_array(el)
        el["height"] ||= el["width"] 
        num_rows    = (el["images"].count / el["rowsize"]).ceil
        tot_margins_x = ( el["rowsize"].to_i + 1 ) * el["margin"].to_i
        tot_margins_y = ( num_rows + 1 ) * el["margin"].to_i
        box_width   = ( el["width"].to_i  - tot_margins_x ) / el["rowsize"].to_i
        box_height  = ( el["height"].to_i - tot_margins_y ) / num_rows
        el["images"].each_with_index do |x,i|
          next if x["img"] == "blank"
          x_offset = el["margin"].to_i + ( el["margin"].to_i + box_width ) * ( i % el["rowsize"] ) + el["x_offset"]
          y_offset = el["margin"].to_i + ( el["margin"].to_i + box_height ) * ( i / el["rowsize"] ) + el["y_offset"]
          geometry = "#{box_width}x#{box_height}+#{x_offset}+#{y_offset}"
          p geometry
          @@image.draw_bubble( x["img"], x["lines"], geometry)
        end
      end

      def draw_event_bubble(opts={})
        opts[:ptscale]  ||= 0.03
        opts[:ptscale2] ||= 0.02
        opts[:margin]   ||= opts[:width] * 0.006
        opts[:height]   ||= opts[:width]
        opts[:radius]   ||= [opts[:width],opts[:height]].min/10
        ptsize  = (opts[:width] * opts[:ptscale]) / 300 * 72
        ptsize2 = (opts[:width] * opts[:ptscale2]) / 300 * 72 
        event = Event[opts[:event_id]] or return
        p opts[:wide]
        img = MiniMagick::Image.open(event.image[:original].url) unless opts[:wide]
        img = MiniMagick::Image.open(event.wide_image.url)       if     opts[:wide]
        img.resize_with_crop(opts[:width].to_i,opts[:height].to_i,{ :geometry => :center })
        img.footer_lines( { :lines => event.poster_lines, :ptsize => ptsize, :ptsize2 => ptsize2 } )
        img.mask_edges(opts)
        self.bubble_shadow(opts)
        self.overlay(img, opts[:width], opts[:height], opts[:x_offset], opts[:y_offset])
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
        self.draw_box(x-margin, y-margin, width+margin*2, height+margin*2, width/10, height/10, Values::WhiteGlow)
        
        result = self.composite(img) do |c|
          c.compose "Over"
          c.geometry "#{width}x#{height}+#{x}+#{y}"
        end
        
        self.clone_img(result)
      end

    end

  end

end