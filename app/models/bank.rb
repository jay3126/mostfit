class Bank
  include DataMapper::Resource
  
  property :id,   Serial
  property :name, String
  property :created_at, DateTime
  property :created_by_user_id, Integer, :nullable => false

  has n, :bank_branches

  belongs_to :user, :child_key => [:created_by_user_id], :model => 'User'

  validates_is_unique :name
  validates_present :name

end
