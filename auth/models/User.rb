require 'bcrypt'

class User < Sequel::Model
    plugin :validation_helpers
    attr_accessor :password, :confirmation

    many_to_one  :customer
    one_to_many :omniaccounts
    many_to_many :roles

    def after_create
      add_role Role[1]
      send_activation
    end

    def has_role?(role)
      return self.roles.include? Role[:name => role ]                        if role.is_a? String
      role.each { |r| return true if self.roles.include? Role[:name => r ] } if role.is_a? Array
      return false
    end

    def name
      customer.name
    end

    def photo_url
      omniaccounts.first.photo_url
    end
    
    def before_save
      encrypt_password unless password.nil?
      super 
    end

    def after_save
      clear_password
      super
    end

    def delete
      self.remove_all_roles
      self.save
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
      return false if self.salt.nil? 
      encrypted_password == BCrypt::Engine.hash_secret( login_password, self.salt )
    end

    def self.authenticate(email="", login_password="")
      customer = Customer.find_by_email(email)
      return false if customer.nil?
      user = customer.login
      return ( user && user.match_password(login_password) ) ? user : nil 
    end

    def activated?
      return !encrypted_password.nil?
    end 

    def reset_password
      self.generateResetToken
      self.send_password_email 
    end

    def send_activation
      self.generateResetToken
      self.send_new_account_email
    end

    def get_reset_token
      self.generateResetToken unless self.reset_token
      self.reset_token
    end

    def send_password_email
      ( Slack.post("Customer #{self.customer.to_list_string} has no email"); return ) if customer.email.nil?
      Mail.password_reset(customer.email, { :name => customer.name, :url => "https://cosmicfitclub.com/auth/activate?token=#{reset_token}" } )
    end

    def send_new_account_email
      ( Slack.post("Customer #{self.customer.to_list_string} has no email"); return ) if customer.email.nil?
      Mail.account_created(customer.email, { :name => customer.name, :url => "https://cosmicfitclub.com/auth/activate?token=#{reset_token}" } )
    end

    def generateResetToken() self.update( :reset_token => rand(36**8).to_s(36) ) end

end