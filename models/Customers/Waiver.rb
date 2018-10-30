class Waiver < Sequel::Model
  many_to_one :customer

  def Waiver::Current_Body
    %{
    	RELEASE OF LIABILITY
    }
  end

end