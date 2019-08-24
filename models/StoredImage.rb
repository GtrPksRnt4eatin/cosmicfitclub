class StoredImage < Sequel::Model

  include ImageUploader[:image]

end