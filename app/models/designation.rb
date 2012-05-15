class Designation
  include DataMapper::Resource
  
  property :id,         Serial
  property :name,       String, :nullable => false
  property :created_at, DateTime, :nullable => false, :default => DateTime.now
  property :deleted_at, ParanoidDateTime, :default => DateTime.now

  belongs_to :location_level

  has n, :user_roles

end
