module MiniMagickExtensions
  
  module Image

  	module Crop

  	  def mask_edges
        mask = MiniMagick::Image.open("printable/assets/mask.png")
        mask.resize "#{self.dimensions[0]}x#{self.dimensions[1]}!"
        result = mask.composite(self,'png') do |c|
          c.compose "src-in"
          c.geometry "+0+0"
        end
        self.clone_img(result)
      end

  	  # from http://www.dweebd.com/ruby/resizing-and-cropping-images-to-fixed-dimensions/

  	  GRAVITY_TYPES = [ :north_west, :north, :north_east, :east, :south_east, :south, :south_west, :west, :center ]

  	  def resize_with_crop(w, h, options = {})
        gravity = options[:gravity] || :center

        w_original, h_original = [self[:width].to_f, self[:height].to_f]

        op_resize = ''

        # check proportions
        if w_original * h < h_original * w
          op_resize = "#{w.to_i}x"
          w_result = w
          h_result = (h_original * w / w_original)
        else
          op_resize = "x#{h.to_i}"
          w_result = (w_original * h / h_original)
          h_result = h
        end

        w_offset, h_offset = crop_offsets_by_gravity(gravity, [w_result, h_result], [ w, h])

        self.combine_options do |i|
          i.resize(op_resize)
          i.gravity(gravity)
          i.crop "#{w.to_i}x#{h.to_i}+#{w_offset}+#{h_offset}!"
        end

        self
      end

      def crop_offsets_by_gravity(gravity, original_dimensions, cropped_dimensions)
        raise(ArgumentError, "Gravity must be one of #{GRAVITY_TYPES.inspect}") unless GRAVITY_TYPES.include?(gravity.to_sym)
        raise(ArgumentError, "Original dimensions must be supplied as a [ width, height ] array") unless original_dimensions.kind_of?(Enumerable) && original_dimensions.size == 2
        raise(ArgumentError, "Cropped dimensions must be supplied as a [ width, height ] array") unless cropped_dimensions.kind_of?(Enumerable) && cropped_dimensions.size == 2

        original_width, original_height = original_dimensions
        cropped_width, cropped_height = cropped_dimensions

        vertical_offset = case gravity
          when :north_west, :north, :north_east then 0
          when :center, :east, :west then [ ((original_height - cropped_height) / 2.0).to_i, 0 ].max
          when :south_west, :south, :south_east then (original_height - cropped_height).to_i
        end

        horizontal_offset = case gravity
          when :north_west, :west, :south_west then 0
          when :center, :north, :south then [ ((original_width - cropped_width) / 2.0).to_i, 0 ].max
          when :north_east, :east, :south_east then (original_width - cropped_width).to_i
        end

        return [ horizontal_offset, vertical_offset ]
      end

    end
  
  end

end