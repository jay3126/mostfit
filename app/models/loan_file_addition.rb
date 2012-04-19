class LoanFileAddition
  include DataMapper::Resource

  property :id,                  Serial
  property :at_branch_id,        Integer, :nullable => false
  property :at_center_id,        Integer, :nullable => false
  property :for_cycle_number,    Integer, :nullable => false, :min => 1
  property :created_by_staff,    Integer, :nullable => false
  property :created_on,          Date, :nullable => false
  property :created_by_user,     Integer, :nullable => false
  property :created_at,          DateTime, :nullable => false, :default => DateTime.now
  
  belongs_to :loan_application
  belongs_to :loan_file

  validates_with_method :loan_file_id, :method => :is_loan_application_compatible_with_loan_file?

  def is_loan_application_compatible_with_loan_file?
    return [false, "Loan file branch id doest not match with loan application branch id"] if loan_application.at_branch_id != loan_file.at_branch_id
    return [false, "Loan file center id doest not match with loan application center id"] if loan_application.at_center_id != loan_file.at_center_id
    return [false, "Loan file center cycle number doest not match with loan application center cycle number"] if loan_application.center_cycle.cycle_number != loan_file.for_cycle_number
  end

  def self.add_to_loan_file(loan_application_id, loan_file, at_branch, at_center, for_cycle_number, by_staff, on_date, by_user)
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
