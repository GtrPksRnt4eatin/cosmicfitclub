module MiniMagickExtensions
 
  module Image

    module Bubbles

       def to_bubble(lines=nil, pt_scale=0.05)
        ptsize = (self.dimensions[0] * pt_scale) / 300 * 72
        self.footer_lines(lines,ptsize,15) unless lines.nil?
        self.mask_edges
      end

      def draw_bubble(path,lines,geometry)
        geo = /(?<width>\d+)x(?<height>\d+)\+(?<x>\d+)\+(?<y>\d+)/.match(geometry)
        @img = MiniMagick::Image.open(path)
        @img.resize_with_crop(geo[:width].to_i,geo[:height].to_i,{ :geometry => :north })
        @img.to_bubble(lines,0.08)
        self.bubble_shadow(geo[:width].to_i,geo[:height].to_i,geo[:x].to_i,geo[:y].to_i)
        self.overlay(@img,geo[:width].to_i,geo[:height].to_i,geo[:x].to_i,geo[:y].to_i)
      end

      def bubble_shadow(width,height,x,y,margin=nil,radius=nil,color=Values::WhiteGlow)
        margin ||= width*0.01
        radius ||= width/10
        self.draw_box(x-margin, y-margin, width+margin*2, height+margin*2, radius, radius, Values::WhiteGlow)
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

      def draw_event_bubble(event_id, x, y, size)
        event = Event[event_id] or return
        img = MiniMagick::Image.open(event.image[:original].url)
        ptsize = (size * 0.045) / 300 * 72
        img.footer_lines(event.poster_lines, ptsize)
        img.mask_edges
        self.bubble_shadow(size,size,x,y,size*0.006)
        self.overlay(img, size, size, x, y)
      rescue
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