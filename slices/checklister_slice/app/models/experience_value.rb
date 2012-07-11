class ExperienceValue
  include DataMapper::Resource
  
  property :id, Serial
  property :name, Text

  def self.generate_seed_data
    ExperienceValue.create!(:name=>"Excellent")
    ExperienceValue.create!(:name=>"Good")
    ExperienceValue.create!(:name=>"Bad")
    ExperienceValue.create!(:name=>"Poor")
  end


end
