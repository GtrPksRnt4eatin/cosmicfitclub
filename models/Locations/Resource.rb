class Resource < Sequel::Model

    many_to_one :location

  def to_token
    { :id => id, :name => name }
  end

end