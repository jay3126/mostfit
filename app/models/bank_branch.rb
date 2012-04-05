class BankBranch
  include DataMapper::Resource
  
  property :id, Serial

  has n, :bank_accounts

  belongs_to :bank

end
