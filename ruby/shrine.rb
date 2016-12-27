require 'shrine'
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
  # image attachent logic
end