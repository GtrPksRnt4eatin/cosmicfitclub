class Pass < Sequel::Model
  
  many_to_one :customer

  def Pass.list_all

  	h = {} 
    passes = Pass.all.map { |p| { :id => p.id, :customer_id => p.customer_id, :customer_name => p.customer.name } }.group_by { |p| p[:customer_id] }
    passes.each { |k,v| passes[k] = { :customer_name => v[0][:customer_name], :count => v.count } }

  end

end
	
class Wallet < Sequel::Model

  one_to_many :customers
  one_to_many :pass_transactions

  def add_passes(number, description, notes)
    add_pass_transaction( PassTransaction.create( :delta => number, :description => description, :notes => notes ) )
    self.pass_balance = self.pass_balance + number
    self.save
  end

  def rem_passes(number, description, notes)
    add_pass_transaction( PassTransaction.create( :delta => -number, :description => description, :notes => notes ) )
    self.pass_balance = self.pass_balance - number
    self.save
  end

end

class PassTransaction < Sequel::Model

  many_to_one :wallet

  def before_create
    self.timestamp = Time.now
    super
  end

end