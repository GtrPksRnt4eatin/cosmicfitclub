class ClassDef < Sequel::Model

  include ImageUploader[:image]

  def after_save
  	self.id
  	super
  end

end