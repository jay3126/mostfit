class Bank
  include DataMapper::Resource
  
  property :id,   Serial
  property :name, String

  has n, :bank_branches

end
