class AssetCategory
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String, :unique => true

  has n, :asset_sub_categories
  has n, :asset_registers

  validates_is_unique :name
  validates_present :name
end
