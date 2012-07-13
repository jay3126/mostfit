class AssetCategory
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String, :unique=>true

  has n, :asset_sub_categories
  has n, :asset_registers

 # validates_is_unique :name
  validates_present :name

def self.write_data(data)
  if AssetCategory.all(:name=>data).count==0
    @asset_category=AssetCategory.create!(:name=>data)
  else
    @asset_category=AssetCategory.all(:name=>data).first
  end
end




end
