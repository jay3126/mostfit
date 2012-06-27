class LoanPurpose
  include DataMapper::Resource
  include Constants::Properties

  property :id,   Serial
  property :name, *UNIQUE_NAME
  
  has n, :lendings

  def to_s
    self.name
  end

end
