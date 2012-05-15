class Customer
  include DataMapper::Resource
  include Constants::Properties
  
  property :id,   Serial
  property :name, *NAME

end
