require 'bcrypt'

class User < Sequel::Model
    plugin :validation_helpers
    attr_accessor :password, :confirmation

    one_to_one  :client
    one_to_many :omniaccounts
    many_to_many :roles

    def has_role?(role)
      roles.include? Role[:name => role]
    end

    def photo_url
      omniaccounts.first.photo_url
    end

    def before_save
      generateResetToken if password.nil?
      encrypt_password unless password.nil?
      super 
    end

    def after_save
      clear_password
      super
    end
    
    def validate
      super
      errors.add(:confirmation, 'must match password') if confirmation != password
    end

    def encrypt_password
      self.salt = BCrypt::Engine.generate_salt
      self.encrypted_password = BCrypt::Engine.hash_secret( password, salt )
    end

    def clear_password
      self.password = nil
    end

    def match_password(login_password="")
      encrypted_password == BCrypt::Engine.hash_secret( login_password, salt )
    end

    def self.authenticate(username_or_email="", login_password="")
      user = ( User[:username=>username_or_email] || User[:email=>username_or_email] )
      return ( user && user.match_password(login_password) ) ? user : false 
    end

    def activated?
      return !encrypted_password.nil?
    end 

    def generateResetToken() self.reset_token = rand(36**8).to_s(36) end

end