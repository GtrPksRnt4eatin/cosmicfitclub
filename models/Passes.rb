class Pass < Sequel::Model
  
  many_to_one :customer

  def Pass.list_all
    list = Wallet.all.map { |w| { :id => w.id, :customer_id => w.customers[0].id, :customer_name => w.customers[0].name, :customer_email => w.customers[0].email, :pass_balance => w[:pass_balance] } }
    list.sort { |a,b| a[:customer_name] <=> b[:customer_name] }.to_json
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

class PassRoutes < Sinatra::Base

  get '/all' do
    Pass.list_all
  end

end