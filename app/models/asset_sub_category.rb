class AssetSubCategory
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String

  belongs_to :asset_category
  has n, :asset_types
  has n, :asset_registers

  validates_present :name
  validates_is_unique :name
end
