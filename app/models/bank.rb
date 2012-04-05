class Bank
  include DataMapper::Resource
  
  property :id, Serial

  has n, :bank_branchs
end
