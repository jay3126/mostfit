class AssetSubCategory
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String

  belongs_to :asset_category
  has n, :asset_types
  has n, :asset_registers

  validates_present :name
  validates_is_unique :name

  def self.write_data(parent_object,data)
    if AssetSubCategory.all(:name=>data).count==0
      @asset_sub_category=parent_object.asset_sub_categories.create(:name=>data)
    else

      @asset_sub_category=AssetSubCategory.all(:name=>data).first

    end
     @asset_sub_category
  end



end
