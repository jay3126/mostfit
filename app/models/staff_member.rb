class StaffMember
  include DataMapper::Resource
  include Identified
  include Pdf::DaySheet if PDF_WRITER

  property :id,            Serial
  property :name,          String, :length => 100, :nullable => false
  property :mobile_number, String, :length => 12,  :nullable => true
  property :creation_date, Date,   :length => 12,  :nullable => true, :default => Date.today
  property :address,       Text,   :lazy => true
  property :father_name,   String, :length => 100, :nullable => true
  property :gender,        Enum.send('[]', *[:female, :male]), :nullable => true, :lazy => true, :default => :male
  property :active,        Boolean, :default => true, :nullable => false
  property :employee_id,   String, :length => 15, :nullable => true

  # no designations, they are derived from the relations it has
  belongs_to :designation
  belongs_to :upload, :nullable => true

  belongs_to :origin_home_location, :model => 'BizLocation', :child_key => [:origin_home_location_id], :nullable => true

  has n, :branch_diaries,    :child_key => [:manager_staff_id]
  has n, :stock_registers,   :child_key => [:manager_staff_id]
  has n, :asset_registers,   :child_key => [:manager_staff_id]
  has n, :payments, :child_key  => [:received_by_staff_id]
  has n, :monthly_targets
  has n, :weeksheets
  has n, :staff_member_attendances

  has 1, :user
  has n, :visit_schedules

  validates_length :name, :min => 3
  validates_is_unique :employee_id

  def created_on; creation_date; end
  def role
    self.designation ? self.designation.role_class : nil
  end

  # tests for role class
  def is_supervisor?; self.designation ? self.designation.is_supervisor? : false; end
  def is_executive?; self.designation ? self.designation.is_executive? : false; end
  def is_support?; self.designation ? self.designation.is_support? : false; end
  def is_finops?; self.designation ? self.designation.is_finops? : false; end
  def is_administrator?; self.designation ? self.designation.is_administrator? : false; end
  def is_supervisor_or_executive?; (is_supervisor?) or (is_executive?); end
  def is_finops_or_supervisor?; (is_finops?) or (is_supervisor?); end

  def self.search(q, per_page)
    if /^\d+$/.match(q)
      all(:conditions => {:id => q}, :limit => per_page)
    else
      all(:conditions => ["name like ?", q+'%'], :limit => per_page)
    end
  end

  def self.from_csv(row, headers)
    designation = Designation.first(:name => row[headers[:designation]])
    raise ArgumentError, "Designation(#{row[headers[:designation]]}) does not exist" if designation.blank?

    mobile = nil
    mobile = row[headers[:mobile_number]] if headers[:mobile_number] and row[headers[:mobile_number]]
    gender = row[headers[:gender]].downcase.to_sym

    obj = new(:name => row[headers[:name]], :creation_date => row[headers[:joining_date]], :gender => gender,
              :employee_id => row[headers[:employee_id]], :mobile_number => mobile, :active => true, :designation => designation,
              :upload_id => row[headers[:upload_id]])
    [obj.save, obj]
  end

  def generate_sheets(date)
    c_pdf = generate_collection_pdf(date)
    d_pdf = generate_disbursement_pdf(date)
    return [c_pdf, d_pdf]
  end

  def is_branch_manager?
    designation = self.designation
    designation.blank? ? false : designation.name == 'Branch Manager'
  end

  def is_ro?
    designation = self.designation
    designation.blank? ? false : designation.name == 'RO'
  end
end
