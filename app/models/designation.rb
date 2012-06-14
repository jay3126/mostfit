class Designation
  include DataMapper::Resource
  include Constants::Properties
  
  property :id,         Serial
  property :name,       String, :nullable => false, :unique => true
  property :created_at, *CREATED_AT
  property :deleted_at, *DELETED_AT

  belongs_to :location_level

  has 1, :user_role

end
