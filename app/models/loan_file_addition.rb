class LoanFileAddition
  include DataMapper::Resource

  property :id,                  Serial
  property :at_branch_id,        Integer,  :nullable => false
  property :at_center_id,        Integer,  :nullable => false
  property :for_cycle_number,    Integer,  :nullable => false, :min => 1
  property :created_by_staff,    Integer,  :nullable => false
  property :created_on,          Date,     :nullable => false
  property :created_by_user,     Integer,  :nullable => false
  property :created_at,          DateTime, :nullable => false, :default => DateTime.now
  
  belongs_to :loan_application
  belongs_to :loan_file

  validates_with_method :at_branch_id,     :method => :is_branch_id_in_sync?
  validates_with_method :at_center_id,     :method => :is_center_id_in_sync?
  validates_with_method :for_cycle_number, :method => :is_cycle_number_in_sync?

  def is_branch_id_in_sync?
    return [false, "Loan file branch id does not match with loan application branch id"] if loan_application.at_branch_id != loan_file.at_branch_id
    return [false, "Loan file Addition branch id does not match with loan application branch id"] if self.at_branch_id != loan_application.at_branch_id
    return [false, "Loan file Addition branch id does not match with loan file branch id"] if self.at_branch_id != loan_file.at_branch_id
    return true
  end

  def is_center_id_in_sync?
    return [false, "Loan file center id does not match with loan application center id"] if loan_application.at_center_id != loan_file.at_center_id
    return [false, "Loan file Addition center id does not match with loan application center id"] if self.at_center_id != loan_application.at_center_id
    return [false, "Loan file Addition center id does not match with loan file center id"] if self.at_center_id != loan_file.at_center_id
    return true
  end

  def is_cycle_number_in_sync?
    return [false, "Loan file center cycle number does not match with loan application center cycle number"] if loan_application.center_cycle.cycle_number != loan_file.for_cycle_number
    return [false, "Loan file Addition center cycle number does not match with loan application center cycle number"] if self.for_cycle_number != loan_application.center_cycle.cycle_number
    return [false, "Loan file Addition center cycle number does not match with loan file center cycle number"] if self.for_cycle_number != loan_file.for_cycle_number
    return true
  end

  
  # @param [Integer]  loan_application_id 
  # @param [LoanFile] loan_file 
  # @param [Integer]  at_branch
  # @param [Integer]  at_center
  # @param [Integer]  for_cycle_number
  # @param [Integer]  by_staff
  # @param [Date]     on_date
  # @param [Integer]  by_user
  def self.add_to_loan_file(loan_application_id, loan_file, at_branch, at_center, for_cycle_number, by_staff, on_date, by_user)
    #    raise ArgumentError, "New loan applications cannot be added to a loan file because its status is '#{loan_file.health_check_status.humanize}' " unless loan_file.health_check_status == Constants::Status::NEW_STATUS
    query_params = {}
    query_params[:loan_application_id] = loan_application_id
    query_params[:loan_file] = loan_file
    query_params[:at_branch_id] = at_branch
    query_params[:at_center_id] = at_center
    query_params[:for_cycle_number] = for_cycle_number
    query_params[:created_by_staff] = by_staff
    query_params[:created_on] = on_date
    query_params[:created_by_user] = by_user
    create(query_params)
  end

end
