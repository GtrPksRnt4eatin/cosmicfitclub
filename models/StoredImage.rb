class StoredImage < Sequel::Model

  include SimpleImageUploader[:image]

  def after_save
  	self.id
  	super
  end

end