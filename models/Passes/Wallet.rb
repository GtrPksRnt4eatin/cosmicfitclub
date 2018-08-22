class Wallet < Sequel::Model

  one_to_many :customers
  one_to_many :transactions, :class => :PassTransaction

  def empty?;  self.pass_balance == 0   end
  def shared?; self.customers.count > 1 end

  def add_passes(number, description, notes)
    transaction = add_transaction( PassTransaction.create( :delta => number.to_i, :description => description, :notes => notes ) )
    self.pass_balance = self.pass_balance + number.to_i
    self.save
    return transaction
  end

  def rem_passes(number, description, notes)
    return false if self.pass_balance < number.to_i
    transaction = PassTransaction.create( :delta => - number.to_i, :description => description, :notes => notes )
    add_transaction( transaction )
    self.pass_balance = self.pass_balance - number.to_i
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

  def history
    hist = self.transactions.sort_by{ |x| x[:timestamp] }.inject([]) do |tot,el|
      el = el.to_hash      
      el[:running_total] = el[:delta] + ( tot.last.nil? ? 0 : tot.last[:running_total] )
      tot << el
    end
  end

end