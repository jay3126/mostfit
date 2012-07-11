class DueSheetFileValue
  include DataMapper::Resource
  
  property :id, Serial
  property :name, Text
  property :marks, Integer

  def self.generate_seed_data
    DueSheetFileValue.create!(:name=>"5 box files maintained and reports filed regularly ",:marks=>3)
    DueSheetFileValue.create!(:name=>"5 box files maintained and reports NOT filed regularly",:marks=>2)
    DueSheetFileValue.create!(:name=>"Box files not maintained ",:marks=>1)
  end


end
