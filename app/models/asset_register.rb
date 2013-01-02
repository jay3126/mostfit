class AssetRegister
  include DataMapper::Resource
  before :save, :convert_blank_to_nil

  property :id, Serial
  property :name, String, :length => 100, :nullable => false, :index => true
  property :issued_to_staff_member_id, Integer, :nullable => true
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
end
