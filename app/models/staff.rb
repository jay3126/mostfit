class Staff
  include DataMapper::Resource
  include Constants::Properties
  
  property :id,         Serial
  property :name,       *NAME
  property :created_at, *CREATED_AT
  property :deleted_at, *DELETED_AT

  has 1, :user

end
