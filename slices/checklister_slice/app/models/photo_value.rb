class PhotoValue
  include DataMapper::Resource
  
  property :id, Serial
  property :name, Text
  property :marks, Integer

  def self.generate_seed_data
    PhotoValue.create!(:name=>"2 photos taken and updated to picasa site ",:marks=>3)
    PhotoValue.create!(:name=>"2 photos taken and not updated to picasa site",:marks=>2)
    PhotoValue.create!(:name=>"Photos not taken ",:marks=>1)
  end


end
