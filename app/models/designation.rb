class Designation
  include DataMapper::Resource
  include Constants::Properties, Constants::User
  
  property :id,         Serial
  property :name,       String, :nullable => false, :unique => true
  property :role_class, Enum.send('[]', *ROLE_CLASSES), :nullable => false
  property :created_at, *CREATED_AT
  property :deleted_at, *DELETED_AT

  belongs_to :location_level
  has n, :staff_members

end
