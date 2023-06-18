require 'shrine'
require 'image_processing/mini_magick'
require 'shrine/storage/s3'

Shrine.storages = {
  cache: Shrine::Storage::S3.new(prefix: "cache", **$S3_options),
  store: Shrine::Storage::S3.new(prefix: "store", **$S3_options)
}

Shrine.plugin :sequel
Shrine.plugin :determine_mime_type
Shrine.plugin :cached_attachment_data
Shrine.plugin :rack_file

class ImageUploader < Shrine 
  
  #include ImageProcessing::MiniMagick
  
  #plugin :processing
  #plugin :versions
  plugin :derivatives, create_on_promote: true, versions_compatibility: true

  #process(:store) do |io, context|
  #  original = io.download
  #  size_800 = resize_to_limit(original, 800, 800)
  #  size_500 = resize_to_limit(size_800, 500, 500)
  #  size_300 = resize_to_limit(size_500, 300, 300)
  #  { original: original, large: size_800, medium: size_500, small: size_300 }
  #end

  Attacher.derivatives do |original|
    magick = ImageProcessing::MiniMagick.source(original)
    { large:  magick.resize_to_limit!(800,800),
      medium: magick.resize_to_limit!(500,500),
      small:  magick.resize_to_limit!(300,300)
    }
  end

end

class SimpleImageUploader < Shrine

end
