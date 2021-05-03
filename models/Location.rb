
class Location < Sequel::Model

    one_to_many :ClassDefs
    one_to_many :ClassDefSchedules

end