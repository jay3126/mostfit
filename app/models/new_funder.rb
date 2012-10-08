class NewFunder
  include DataMapper::Resource

  property :id,           Serial
  property :name,         String, :length => 50, :nullable => false, :unique => true
  property :created_by,   Integer
  property :created_at,   DateTime, :nullable => false, :default => DateTime.now

  has n, :new_funding_lines

end