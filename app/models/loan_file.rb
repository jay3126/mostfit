class LoanFileInfo

  attr_reader :loan_file_identifier, :at_branch_id, :at_center_id, :for_cycle_number, :scheduled_disbursal_date, :scheduled_first_payment_date, :created_by_staff_id, :created_on, :created_by, :created_at, :loan_applications

  def initialize(loan_file_identifier, at_branch_id, at_center_id, for_cycle_number, scheduled_disbursal_date, scheduled_first_payment_date, created_by_staff_id, created_on, created_by, created_at, loan_applications = [])
    @loan_file_identifier = loan_file_identifier
    @at_branch_id = at_branch_id
    @at_center_id = at_center_id
    @for_cycle_number = for_cycle_number
    @scheduled_disbursal_date = scheduled_disbursal_date
    @scheduled_first_payment_date = scheduled_first_payment_date
    @created_by_staff_id = created_by_staff_id
    @created_on = created_on
    @created_by = created_by
    @created_at = created_at
    @loan_applications = loan_applications
  end

end

# A loan file lists a number of loan applications that are being processed together
class LoanFile
  include DataMapper::Resource
  include Constants::Status

  property :id,                   Serial
  property :at_branch_id,         Integer, :nullable => false
  property :at_center_id,         Integer, :nullable => false
  property :for_cycle_number,     Integer, :nullable => false
  property :loan_file_identifier, String, :nullable => false,
    :default => lambda {|obj, p| "#{obj.at_branch_id}_#{obj.at_center_id}_#{obj.created_on.strftime('%d-%m-%Y')}"}
  property :scheduled_disbursal_date, Date, :nullable => false
  property :scheduled_first_payment_date, Date, :nullable => false
  property :created_by_staff_id,  Integer, :nullable => false
  property :created_on,           Date, :nullable => false
  property :created_by,           Integer, :nullable => false
  property :created_at,           DateTime, :nullable => false, :default => DateTime.now
  property :health_check_status,  Enum.send('[]', *HEALTH_CHECK_STATUSES), :nullable => false, :default => HEALTH_CHECK_PENDING
  property :health_status_remark, Text, :nullable => true, :lazy => true
  
  has n, :loan_file_additions
  has n, :loan_applications, :through => :loan_file_additions

  def to_info
    loan_applications = self.loan_applications.collect{|lap| lap.to_info}
    LoanFileInfo.new(loan_file_identifier, at_branch_id, at_center_id, for_cycle_number, scheduled_disbursal_date, scheduled_first_payment_date, created_on, created_by_staff_id, created_by, created_at, loan_applications)
  end

  def self.generate_loan_file(at_branch, at_center, for_cycle_number, scheduled_disbursal_date, scheduled_first_payment_date, by_staff, on_date, by_user)
    query_params = {}
    query_params[:at_branch_id] = at_branch
    query_params[:at_center_id] = at_center
    query_params[:for_cycle_number] = for_cycle_number
    query_params[:scheduled_disbursal_date] = scheduled_disbursal_date
    query_params[:scheduled_first_payment_date] = scheduled_first_payment_date
    query_params[:created_by_staff_id] = by_staff
    query_params[:created_on] = on_date
    query_params[:created_by] = by_user
    create(query_params)
  end

  def self.locate_loan_file(by_identifier)
    first(:loan_file_identifier => by_identifier)
  end

  def self.locate_loan_file_at_center(at_branch, at_center, for_cycle_number)
    first(:at_branch_id => at_branch, :at_center_id => at_center, :for_cycle_number => for_cycle_number).to_info
  end
  
  def self.locate_loan_files_at_center_at_branch_for_cycle(at_branch, at_center, for_cycle_number)
    loan_files_infos = all(:at_branch_id => at_branch, 
                     :at_center_id => at_center, 
                     :for_cycle_number => for_cycle_number).collect { |lf| lf.to_info}
    loan_files_infos
  end

  def self.get_loan_file_info(loan_file_identifier)
    loan_file = locate_loan_file(loan_file_identifier)
    loan_file ? loan_file.to_info : nil
  end

end
