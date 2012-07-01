class LoanPurpose
  include DataMapper::Resource
  include Constants::Properties

  property :id,   Serial
  property :name, *UNIQUE_NAME
  
  def to_s
    self.name
  end

end
