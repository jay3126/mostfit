class PslSubCategory
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String
  
  validates_present   :name
  validates_is_unique :name

  belongs_to :priority_sector_list
end
