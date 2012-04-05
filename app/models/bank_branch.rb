class BankBranch
  include DataMapper::Resource
  
  property :id,   Serial
  property :name, String, :length => 100, :nullable => false, :index => true

  has n, :bank_accounts

  belongs_to :bank

end
