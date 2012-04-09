class BankAccount
  include DataMapper::Resource
  
  property :id,         Serial
  property :name,       String, :length => 100, :nullable => false, :index => true
  property :created_at, DateTime
  property :created_by_user_id, Integer, :nullable => false


  has n, :money_deposits

  belongs_to :bank_branch
  belongs_to :user, :child_key => [:created_by_user_id], :model => 'User'

  validates_is_unique :name, :scope => :bank_branch_id
  validates_present :name, :scope => :bank_branch_id
end
