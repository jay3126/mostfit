class InfrastructureValue
  include DataMapper::Resource
  
  property :id, Serial
  property :name, Text
  property :marks, Integer

  def self.generate_seed_data
    InfrastructureValue.create!(:name=>"RBI registration certificate/Shop Act/Company registration ",:marks=>6)
    InfrastructureValue.create!(:name=>"Area survey chart/ branch approval ",:marks=>5)
    InfrastructureValue.create!(:name=>"RO capacity chart ",:marks=>4)
    InfrastructureValue.create!(:name=>"Branch information in White Board as per format ",:marks=>3)
    InfrastructureValue.create!(:name=>"Copy of process note and training kit ",:marks=>2)
    InfrastructureValue.create!(:name=>"Working of PC and Net ",:marks=>1)
  end


end
