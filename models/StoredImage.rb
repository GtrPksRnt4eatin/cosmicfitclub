class StoredImage < Sequel::Model

  include SimpleImageUploader[:image]

  def after_save
  	self.id
  	super
  end

  def url
  	self.image.url
  end

end