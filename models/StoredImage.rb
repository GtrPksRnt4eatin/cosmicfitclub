class StoredImage < Sequel::Model

  include SimpleImageUploader[:image]

  def after_save
  	self.id
  	super
  end

  def url
  	self.image.url
  end

  def details_hash
    {  :url => self.url,
       :image_data => self.image_data
    }
  end

end