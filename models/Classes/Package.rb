class Package < Sequel::Model

  def price
  	return 0 if pass_price.nil?
  	return 0 if num_passes.nil?
  	pass_price.to_f * num_passes.to_f
  end

  def formatted_price
    "$%.2f" % (price / 100.0)
  end

end