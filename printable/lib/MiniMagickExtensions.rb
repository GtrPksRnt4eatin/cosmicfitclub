require_relative './MiniMagickExtensions::Image::Bubbles.rb'
require_relative './MiniMagickExtensions::Image::Builder.rb'
require_relative './MiniMagickExtensions::Image::Crop.rb'
require_relative './MiniMagickExtensions::Image::Loading.rb'
require_relative './MiniMagickExtensions::Image::Text.rb'
require_relative './MiniMagickExtensions::Image::Values.rb'
require_relative './MiniMagickExtensions::Image::Elements.rb'

MiniMagick::Image.include MiniMagickExtensions::Image::Bubbles
MiniMagick::Image.include MiniMagickExtensions::Image::Builder
MiniMagick::Image.include MiniMagickExtensions::Image::Crop
MiniMagick::Image.include MiniMagickExtensions::Image::Loading
MiniMagick::Image.include MiniMagickExtensions::Image::Text
MiniMagick::Image.include MiniMagickExtensions::Image::Elements