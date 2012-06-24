class Address
  include DataMapper::Resource
  include Constants::Properties

  property :id,             Serial
  property :address_line_1, String, :length => LONG_STRING_LENGTH, :nullable => false
  property :address_line_2, *LONG_STRING

  belongs_to :address_state
  belongs_to :address_town
  belongs_to :address_pin_code
  belongs_to :biz_location

  def full_address_text
    "#{address_line_1}#{(', ' + address_line_2.to_s) if address_line_2}, #{address_town.to_s}, #{address_state.to_s}, #{address_pin_code.to_s}"
  end
end

class AddressPinCode
  include DataMapper::Resource
  include Constants::Properties

  property :id,       Serial
  property :pin_code, String, :length => LONG_STRING_LENGTH, :nullable => false, :unique => true

  belongs_to :biz_location
  belongs_to :address_town
  has n, :addresses

  def to_s
    "Pin Code: #{pin_code}"
  end
end

class AddressTown
  include DataMapper::Resource
  include Constants::Properties

  property :id,   Serial
  property :name, String, :length => LONG_STRING_LENGTH, :nullable => false

  belongs_to :address_state
  has n, :addresses
  has n, :address_pin_codes, 'AddressPinCode'

  def to_s
    "#{name}"
  end
end

class AddressState
  include DataMapper::Resource
  include Constants::Properties

  property :id,   Serial
  property :name, String, :length => LONG_STRING_LENGTH, :nullable => false

  def to_s
    "#{name}"
  end
end
