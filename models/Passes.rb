class Pass < Sequel::Model
  
  many_to_one :customer

  def Pass.list_all
    list = Wallet.all.map { |w| { :id => w.id, :customer_id => w.customers[0].id, :customer_name => w.customers[0].name, :customer_email => w.customers[0].email, :pass_balance => w[:pass_balance] } }
    list.sort { |a,b| a[:customer_name] <=> b[:customer_name] }.to_json
  end

end
	
class Wallet < Sequel::Model

  one_to_many :customers
  one_to_many :transactions, :class => :PassTransaction

  def empty?; self.pass_balance == 0 end

  def add_passes(number, description, notes)
    transaction = add_transaction( PassTransaction.create( :delta => number, :description => description, :notes => notes ) )
    self.pass_balance = self.pass_balance + number
    self.save
    return transaction
  end

  def rem_passes(number, description, notes)
    return false if self.pass_balance < number
    transaction = PassTransaction.create( :delta => -number, :description => description, :notes => notes )
    add_transaction( transaction )
    self.pass_balance = self.pass_balance - number
    self.save
    return transaction
  end

  def use_pass(reason)
    return false if self.empty?
    transaction = PassTransaction.create( :delta=>-1, :description=>reason, :notes=>"" ) { |trans| trans.reservation = yield }
    add_transaction( transaction )
    self.pass_balance = self.pass_balance - 1
    self.save
    return transaction
  end

end

class PassTransaction < Sequel::Model

  many_to_one :reservation, :class => :ClassReservation, :id => :reservation_id
  many_to_one :wallet

  def before_create
    self.timestamp = Time.now
    super
  end

  def undo
    self.wallet.update( :pass_balance => self.wallet.pass_balance - self.delta )
    self.delete
  end

end

class CompTicket < Sinatra::Base

  many_to_one :customer
  many_to_one :pass_transaction

  def before_create
    self.code = generate_code
    super
  end

  def generate_code
    rand(36**8).to_s(36)
  end

  def redeem
    transaction = self.customer.add_passes(1, "First Visit Comp", "")
    self.pass_transaction = transaction
    self.save
  end

end

class PassRoutes < Sinatra::Base

  get '/all' do
    Pass.list_all
  end

  post '/compticket' do
    custy = Customer[params[:customer_id]]
    halt 404 if custy.nil?
    halt 409 if custy.comp_tickets.count > 0
    comp = CompTicket.create(:customer => custy)
    comp.redeem
    status 203
  end

end