class NewFunder
  include DataMapper::Resource
  include Constants::Properties

  property :id,           Serial
  property :name,         String, :length => 50, :nullable => false, :unique => true
  property :created_by,   Integer
  property :created_at,   *CREATED_AT

  has n, :new_funding_lines

end
