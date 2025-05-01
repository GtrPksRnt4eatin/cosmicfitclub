class Wallet < Sequel::Model

  one_to_many :customers
  one_to_many :transactions, :class => :PassTransaction

  def empty?;  self.pass_balance == 0   end
  def shared?; self.customers.count > 1 end

  def force_delete
    self.transactions.each { |t| t.undo }
    self.delete
  end
  
  def delete
    return false unless can_delete?
    self.customers.each { |x| x.update( :wallet_id => nil ) }
    super
  end

  def can_delete?
    return false if self.transactions.count > 0
    return false unless empty?
    return true
  end

  def add_passes(number, description, notes)
    transaction = add_transaction( PassTransaction.create( :delta => number, :description => description, :notes => notes ) )
    self.pass_balance = self.pass_balance + number
    self.fractional_balance + number
    self.save
    return transaction
  end

  def rem_passes(number, description, notes)
    return false if self.pass_balance < number
    transaction = PassTransaction.create( :delta => - number, :description => description, :notes => notes )
    add_transaction( transaction )
    self.pass_balance = self.pass_balance - number
    self.fractional_balance = self.fractional_balance - number
    self.save
    return transaction
  end

  def use_pass(reason,number=1)
    return false if self.empty?
    return false if self.pass_balance < number
    transaction = PassTransaction.create( :delta=> - number, :description=>reason, :notes=>"" ) { |trans| trans.reservation = yield }
    add_transaction( transaction )
    self.pass_balance = self.pass_balance - number
    self.fractional_balance = self.fractional_balance - number
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

  def <<(other)
    other.transactions.each { |t| t.update( :wallet_id => self.id ) }
    self.pass_balance = self.pass_balance + other.pass_balance
    self.fractional_balance = self.fractional_balance + other.fractional_balance
    other.update( :pass_balance => 0 )
    other.delete
    self.save
  end

  def ledger
    history.map{ |x| "#{x[:timestamp].strftime('%d/%m/%Y %I:%M:%S %P')} - #{x[:description].ljust(120)} - #{x[:delta]} - #{x[:running_total]}" }.join("\r\n")
  end

end