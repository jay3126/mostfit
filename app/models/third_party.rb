class ThirdParty
  include DataMapper::Resource
  include Constants::Properties
  
  property :id,          Serial
  property :name,        String, :length => 255, :unique => true, :nullable => false
  property :recorded_by, Integer
  property :created_at,  *CREATED_AT
  
  has n, :securitizations, :through => Resource
  has n, :encumberances, :through => Resource 
  
  def save
	return false
  end
  
  def destroy  
	return false
  end 
  
    
end
