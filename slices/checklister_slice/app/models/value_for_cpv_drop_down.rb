class ValueForCpvDropDown
  include DataMapper::Resource
  
  property :id, Serial
  property :name, Text

  def self.generate_seed_data
    ValueForCpvDropDown.create!(:name=>"Visited all members house")
    ValueForCpvDropDown.create!(:name=>"Not Visited")
    ValueForCpvDropDown.create!(:name=>"Verified at any center ")
  end


end
