module MiniMagickExtensions
 
  module Image

    module Builder

      def draw_elements(elements)

        elements.each do |el|
          case el[:type]
          when "logo"
            self.draw_logo(el[:x_offset],el[:y_offset],el[:width])
          when "box"            
            self.draw_box(el)
          when "text"           
            self.draw_text(el[:text],el[:ptsize],el[:x_offset],el[:y_offset],el[:gravity])
          when "text_header"
            self.draw_text_header(el[:text],el[:ptsize],el[:x_offset],el[:y_offset],el[:gravity])
          when "highlight_text"
            self.draw_highlight_text(el[:text],el[:ptsize],el[:x_offset],el[:y_offset], { :gravity => el[:gravity] }.merge(el) )
          when "img_array"
            el[:margin_x] ||= el[:margin]
            el[:margin_y] ||= el[:margin_x]
            el[:height]   ||= el[:width] 
            num_rows    = (el[:images].count / el[:rowsize]).ceil
            tot_margins_x = ( el[:rowsize].to_i + 1 ) * el[:margin_x].to_i
            tot_margins_y = ( num_rows + 1 ) * el[:margin_y].to_i
            box_width   = ( el[:width].to_i  - tot_margins_x ) / el[:rowsize].to_i
            box_height  = ( el[:height].to_i - tot_margins_y ) / num_rows
            el[:images].each_with_index do |x,i|
              next if x.nil?
              next if x[:img] == "blank"
              x_offset = el[:margin_x].to_i + ( el[:margin_x].to_i + box_width ) * ( i % el[:rowsize] ) + el[:x_offset]
              y_offset = el[:margin_y].to_i + ( el[:margin_y].to_i + box_height ) * ( i / el[:rowsize] ) + el[:y_offset]
              geometry = "#{box_width}x#{box_height}+#{x_offset}+#{y_offset}"
              p geometry
              self.draw_bubble( x[:img], x[:lines], geometry, { :ptscale => el[:ptscale], :ptscale2 => el[:ptscale2] } )
            end
          when "image_bubble"
            self.draw_bubble( el[:img], el[:lines], el[:geometry], el)
          when "event_bubble"
            self.draw_event_bubble(el)
          when "footer"
            self.draw_footer
          when "bubble_shadow"
            self.bubble_shadow(el)
          end
        end
        self

      end

    end

  end

end
