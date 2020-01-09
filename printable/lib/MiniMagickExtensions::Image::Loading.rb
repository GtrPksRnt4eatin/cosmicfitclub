module MiniMagickExtensions
 
  module Image

   module Loading

      def clone_img(other)
        @path = other.path
        @info.clear
        self       
      end

      def save(filename)
        self.write("printable/results/#{filename}")
      end

      def overlay(img, width, height, x, y)
        result = self.composite(img) do |c|
          c.compose "Over"
          c.geometry "#{width}x#{height}+#{x}+#{y}"
        end
        self.clone_img(result)
      end

      #def convert
      #  MiniMagick::Tool::Convert.new do |builder|
      #    yield builder if block_given?
      #  end
      #  @info.clear
      #  self
      #end

    end

  end

end