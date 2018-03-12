class Pass < Sequel::Model
  
  many_to_one :customer

  def Pass.list_all
    list = Wallet.all.map { |w| { :id => w.id, :customer_id => w.customers[0].id, :customer_name => w.customers[0].name, :customer_email => w.customers[0].email, :pass_balance => w[:pass_balance] } }
    list.sort { |a,b| a[:customer_name] <=> b[:customer_name] }.to_json
  end

end