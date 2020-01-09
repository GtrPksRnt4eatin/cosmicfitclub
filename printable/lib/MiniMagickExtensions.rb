require_relative './MiniMagickExtensions::Image::Bubbles'
require_relative './MiniMagickExtensions::Image::Builder'
require_relative './MiniMagickExtensions::Image::Crop'
require_relative './MiniMagickExtensions::Image::Loading'
require_relative './MiniMagickExtensions::Image::Text'
require_relative './MiniMagickExtensions::Image::Values'
require_relative './MiniMagickExtensions::Image::Elements'

MiniMagick::Image.include MiniMagickExtensions::Image::Bubbles
MiniMagick::Image.include MiniMagickExtensions::Image::Builder
MiniMagick::Image.include MiniMagickExtensions::Image::Crop
MiniMagick::Image.include MiniMagickExtensions::Image::Loading
MiniMagick::Image.include MiniMagickExtensions::Image::Text
MiniMagick::Image.include MiniMagickExtensions::Image::Elements