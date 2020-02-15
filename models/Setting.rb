
class Setting < Sequel::Model
  
  unrestrict_primary_key

  def to_json
    val.to_json
  end

end
