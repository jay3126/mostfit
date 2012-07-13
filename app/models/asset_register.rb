class AssetRegister
  include DataMapper::Resource
  before :save, :convert_blank_to_nil

  property :id, Serial
  property :name, String, :length => 100, :nullable => false, :index => true
  #property :asset_type,      String,  :length => 100,         :nullable => false
  property :issue_date, Date, :default => Date.today, :nullable => false
  property :returned_date, Date, :nullable => true
  property :issued_by, String, :length => 100


  #---- done by ptotem team

  property :tag_no, String, :nullable => false

  property :name_of_the_item, Text
  property :name_of_the_vendor, Text

  property :invoice_number, String
  property :invoice_date, Date
  property :make, String
  property :asset_model, String
  property :serial_no, String
  property :date, Date

  belongs_to :asset_category
  belongs_to :asset_sub_category
  belongs_to :asset_type

  belongs_to :biz_location
  #---------------

  belongs_to :manager, :child_key => [:manager_staff_id], :model => 'StaffMember'

  #belongs_to :asset_type

  validates_present :name
  validates_present :manager
  validates_with_method :manager, :manager_is_an_active_staff_member?

  private
  def manager_is_an_active_staff_member?
    return true if manager and manager.active
    [false, "Managing staff member is currently not active"]
  end

  def convert_blank_to_nil
    self.attributes.each { |k, v|
      if v.is_a?(String) and v.empty? and self.class.properties.find { |x| x.name == k }.type==Integer
        self.send("#{k}=", nil)
      end
    }
  end


  def self.write_data(argument_array)
    object_hash=Hash.new
    #@branch=Branch.first(:name=>argument_array[0])
    #if @branch.nil?
    #  @branch=Branch.create!(:name=>argument_array[0])
    #end

    object_hash[:biz_location_id]=BizLocation.all(:name => argument_array[0]).first.id
    asset_category=AssetCategory.first(:name => argument_array[1])
    if asset_category.nil?
      asset_category=AssetCategory.create(:name => argument_array[1])
    end
    asset_sub_category=AssetSubCategory.first(:name => argument_array[2], :asset_category_id => asset_category.id)
    if asset_sub_category.nil?
      asset_sub_category=AssetSubCategory.create(:name => argument_array[2], :asset_category_id => asset_category.id)

    end
    asset_type=AssetType.first(:name => argument_array[3], :asset_sub_category_id => asset_sub_category.id)
    if asset_type.nil?
      asset_type=AssetType.create!(:name => argument_array[3], :asset_sub_category_id => asset_sub_category.id)

    end


    object_hash[:asset_category_id]=asset_category.id

    object_hash[:asset_sub_category_id]=asset_sub_category.id
    object_hash[:asset_type_id]=asset_type.id
    object_hash[:tag_no]=argument_array[4]
    object_hash[:name_of_the_item]=argument_array[5]
    object_hash[:name_of_the_vendor]=argument_array[6]
    object_hash[:invoice_date]=argument_array[8]
    object_hash[:invoice_number]=argument_array[7]
    object_hash[:make]=argument_array[9]
    object_hash[:asset_model]=argument_array[10]
    object_hash[:serial_no]=argument_array[11]
    object_hash[:date]=argument_array[12]
    object_hash[:issue_date]=Date.today#argument_array[13]
    object_hash[:name]="somename"
    object_hash[:manager_staff_id]=1

    AssetRegister.create!(object_hash)


  end
end





