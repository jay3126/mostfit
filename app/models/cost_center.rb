class CostCenter
  include DataMapper::Resource
  include Constants::Accounting
  
  property :id,         Serial
  property :name,       String, :nullable => false, :unique => true,
    :default => lambda {|obj, p| obj.biz_location.name if (obj.biz_location and obj.biz_location.name)}
  property :created_at, DateTime, :nullable => false, :default => DateTime.now

  belongs_to :biz_location, 'BizLocation', :nullable => true

  validates_present :name

  def self.resolve_cost_center_by_branch(branch_id)
  	first_or_create(:biz_location_id => branch_id)
  end

  def self.setup_cost_centers(nominal_branches = [])
    first_or_create(:name => DEFAULT_HEAD_OFFICE_COST_CENTER_NAME)
    nominal_branches.each { |branch_id|
      resolve_cost_center_by_branch(branch_id)
    }
  end

  def to_s
    "Cost center: #{name}"
  end

  def <=>(other)
    (other and other.respond_to?(:name)) ? self.name <=> other.name : nil
  end

end