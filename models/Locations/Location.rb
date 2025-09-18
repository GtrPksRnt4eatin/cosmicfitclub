
class Location < Sequel::Model

    one_to_many :Resources
    one_to_many :ClassDefs
    one_to_many :ClassDefSchedules

  def to_token
    { :id => id, :name => name }
  end

end