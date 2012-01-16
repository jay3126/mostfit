class LoanPool
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String

  has n, :loans

end
