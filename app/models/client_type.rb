class ClientType
  include DataMapper::Resource
  
  property :id, Serial

  property :type, String


  def name
    type
  end

end

begin
  if ClientType.count==0
    ClientType.create(:type => "Standard client")
  end
rescue
end
