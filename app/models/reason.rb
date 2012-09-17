class Reason
  include DataMapper::Resource

  property :id,         Serial
  property :name,       Text, :min => 5
  property :created_at, DateTime

  validates_is_unique :name
  validates_present :name
  
  has n, :comments

end
