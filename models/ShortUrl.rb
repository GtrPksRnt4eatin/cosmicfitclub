class ShortUrl < Sequel::Model

  one_to_one :event

end