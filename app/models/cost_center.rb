class CostCenter
  include DataMapper::Resource
  include Constants::Accounting
  
  property :id,         Serial
  property :name,       String, :nullable => false, :unique => true
  property :created_at, DateTime, :nullable => false, :default => DateTime.now

  belongs_to :branch, :nullable => true

  validates_present :name

  def self.resolve_cost_center_by_branch(branch_id)
  	first(:branch_id => branch_id)
  end

  def self.setup_cost_centers
    first_or_create(:name => DEFAULT_HEAD_OFFICE_COST_CENTER_NAME)
    create_cost_centers_for_branches
  end

  def to_s
    "Cost center: #{name}"
  end

  def <=>(other)
    (other and other.respond_to?(:name)) ? self.name <=> other.name : 1
  end

  private

  def self.create_cost_centers_for_branches
    Branch.all.each {|br| create_cost_center_for_branch(br)}
  end
  
  def self.create_cost_center_for_branch(branch)
    first_or_create(:name => branch.name, :branch => branch)
  end

end