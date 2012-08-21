class ApiAccess
  include DataMapper::Resource
  
  property :id, Serial
  property :origin, String, :nullable => false
  property :description, String, :nullable => false


  validates_is_unique   :origin
end
