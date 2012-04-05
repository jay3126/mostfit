class BankAccount
  include DataMapper::Resource
  
  property :id,         Serial
  property :name,       String, :length => 100, :nullable => false, :index => true
  property :created_at, DateTime

  has n, :money_deposits

  belongs_to :bank_branch



end
