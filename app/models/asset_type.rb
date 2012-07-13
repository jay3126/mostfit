class AssetType
  include DataMapper::Resource

  property :id, Serial
  property :name, String

  belongs_to :asset_sub_category
  has n, :asset_registers

  validates_present :name

  def self.write_data(parent_object, data)
    if AssetType.all(:name => data).count==0
      @asset_type=parent_object.asset_types.create(:name => data)
    else

      @asset_type=AssetType.all(:name => data).first

    end
    @asset_type
  end


end
