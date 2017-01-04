class User < Sequel::Model

	one_to_many :omniaccounts
	many_to_many :roles

	def has_role?(role)
      roles.include? Role[:name => role]
	end

	def photo_url
      omniaccounts.first.photo_url
	end

end
