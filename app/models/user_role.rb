class UserRole
  include DataMapper::Resource
  include Constants::User

  property :id,   Serial
  property :name, String, :nullable => false
  property :role_class, Enum.send('[]', *ROLE_CLASSES), :nullable => false
  property :created_at, DateTime, :nullable => false, :default => DateTime.now
  property :deleted_at, DateTime, :default => DateTime.now

  belongs_to :designation

end
