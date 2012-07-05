# All operations on loan applications and underlying associations go through this facade
class LoanApplicationsFacade < StandardFacade

  def create_for_client(loan_money_amount, client, loan_amount, at_branch, at_center, for_cycle, by_staff, on_date)
    hash = client.to_loan_application + {
      :amount              => loan_money_amount.amount.to_i,
      :currency            => loan_money_amount.currency,
      :created_by_staff_id => by_staff,
      :at_branch_id        => at_branch,
      :at_center_id        => at_center,
      :created_by_user_id  => user_id,
      :center_cycle_id     => for_cycle,
      :created_on          => on_date
    }
    loan_application = LoanApplication.new(hash)
  end

  def get_all_loan_applications_for_branch_and_center(search_options = {})
    LoanApplication.get_all_loan_applications_for_branch_and_center(search_options)
  end
  # General information
  def get_loan_application_status(loan_application_id)
    loan_application = LoanApplication.get(loan_application_id)
    raise NotFound if loan_application.nil?
    loan_application.get_status
  end

  def get_loan_application_info(loan_application_id)
    loan_application = LoanApplication.get(loan_application_id)
    raise NotFound if loan_application.nil?
    loan_application.to_info
  end

  # Rate suspect on de-dupe

  def rate_suspected_duplicate(loan_application_id)
    loan_application = LoanApplication.get(loan_application_id)
    raise NotFound if loan_application.nil?
    loan_application.set_status(Constants::Status::SUSPECTED_DUPLICATE_STATUS)
  end

  def not_duplicate(loan_application_id)
    loan_application = LoanApplication.get(loan_application_id)
    raise NotFound if loan_application.nil?
    loan_application.set_status(Constants::Status::NOT_DUPLICATE_STATUS)
  end

  # Rate on credit bureau response

  def rate_by_credit_bureau_response(loan_application_id, rating)
    loan_application = LoanApplication.get(loan_application_id)
    raise NotFound if loan_application.nil?
    loan_application.record_credit_bureau_response(rating)
  end

  # Loan authorization

  def check_loan_authorization_status(credit_bureau_status, authorization_status)
    LoanApplication.check_loan_authorization_status(credit_bureau_status, authorization_status)
  end

  def authorize_approve(loan_application_id, by_staff, on_date)
    LoanApplication.record_authorization(loan_application_id, Constants::Status::APPLICATION_APPROVED, by_staff, on_date, user_id)
  end

  def authorize_approve_override(loan_application_id, by_staff, on_date, override_reason)
    LoanApplication.record_authorization(loan_application_id, Constants::Status::APPLICATION_OVERRIDE_APPROVED, by_staff, on_date, user_id, override_reason)
  end

  def authorize_reject(loan_application_id,by_staff, on_date)
    LoanApplication.record_authorization(loan_application_id, Constants::Status::APPLICATION_REJECTED, by_staff, on_date, user_id)
  end

  def authorize_reject_override(loan_application_id, by_staff, on_date, override_reason)
    LoanApplication.record_authorization(loan_application_id, Constants::Status::APPLICATION_OVERRIDE_REJECTED, by_staff, on_date, user_id, override_reason)
  end

  # CPVs

  def record_CPV1_approved(loan_application_id, by_staff, on_date)
    loan_application = LoanApplication.get(loan_application_id)
    raise NotFound if loan_application.nil?
    loan_application.record_CPV1_approved(by_staff, on_date, user_id)
  end

  def record_CPV1_rejected(loan_application_id, by_staff, on_date)
    loan_application = LoanApplication.get(loan_application_id)
    raise NotFound if loan_application.nil?
    loan_application.record_CPV1_rejected(by_staff, on_date, user_id)
  end

  def record_CPV2_approved(loan_application_id, by_staff, on_date)
    loan_application = LoanApplication.get(loan_application_id)
    raise NotFound if loan_application.nil?
    loan_application.record_CPV2_approved(by_staff, on_date, user_id)
  end

  def record_CPV2_rejected(loan_application_id, by_staff, on_date)
    loan_application = LoanApplication.get(loan_application_id)
    raise NotFound if loan_application.nil?
    loan_application.record_CPV2_rejected(by_staff, on_date, user_id)
  end

  # Locate center cycle information

  def get_current_center_cycle_number(at_center_id)
    CenterCycle.get_current_center_cycle(at_center_id)
  end

  def get_center_cycle(at_center_id, for_cycle_number)
    CenterCycle.get_cycle(at_center_id, for_cycle_number)
  end

  # Locate loan applications in progress

  # Returns a list of all client IDs for existing clients that have a loan application
  # submitted at a center for a given center cycle
  def all_loan_application_client_ids_for_center_cycle(for_center_id, for_center_cycle)
    LoanApplication.all_loan_application_client_ids_for_center_cycle(for_center_id, for_center_cycle)
  end

  # Locate loan files

  def locate_loan_file(by_loan_file_identifier)
    LoanFile.locate_loan_file(by_loan_file_identifier)
  end

  #get a single loan file at a center, at a branch for a cycle number
  def locate_loan_file_at_center(at_branch, at_center, for_cycle_number)
    LoanFile.locate_loan_file_at_center(at_branch, at_center, for_cycle_number)
  end

  def get_loan_file_info(loan_file_identifier)
    LoanFile.get_loan_file_info(loan_file_identifier)
  end

  #return all loan files at a center in a branch for cycle number
  def locate_loan_files_at_center_at_branch_for_cycle(at_branch, at_center, for_cycle_number)
    LoanFile.locate_loan_files_at_center_at_branch_for_cycle(at_branch, at_center, for_cycle_number)
  end

  # Create loan file

  def create_loan_file(at_branch, at_center, for_cycle_number, scheduled_disbursal_date, scheduled_first_payment_date, by_staff, on_date, *loan_application_id)
    LoanApplication.create_loan_file(at_branch, at_center, for_cycle_number, scheduled_disbursal_date, scheduled_first_payment_date, by_staff, on_date, user_id, *loan_application_id)
  end

  def add_to_loan_file(on_loan_file, at_branch, at_center, for_cycle_number, by_staff, on_date, *loan_application_id)
    LoanApplication.add_to_loan_file(on_loan_file, at_branch, at_center, for_cycle_number, by_staff, on_date, user_id, *loan_application_id)
  end

  # De-dupe

  # returns all loan applications which are pending for de-dupe process
  def self.pending_dedupe
    LoanApplication.pending_dedupe
  end

  # returns all loan applications which has status not_duplicate
  def self.not_duplicate
    LoanApplication.not_duplicate
  end

  # Return all loan applications which has status suspected_duplicate
  def suspected_duplicate(search_options = {})
    LoanApplication.suspected_duplicate(search_options)
  end

  # set loan application status as cleared_not_duplicate
  def set_cleared_not_duplicate(lap_id)
    LoanApplication.set_cleared_not_duplicate(lap_id)
  end

  # set loan application status as confirm_duplicate
  def set_confirm_duplicate(lap_id)
    LoanApplication.set_confirm_duplicate(lap_id)
  end

  def pending_credit_bureau_check(search_options = {})
    LoanApplication.pending_overlap_report_request_generation(search_options)
  end

  def pending_authorization(search_options = {})
    LoanApplication.pending_authorization(search_options)
  end

  def pending_CPV(search_options = {})
    LoanApplication.pending_CPV(search_options)
  end

  def recently_recorded_CPV(search_options = {})
    LoanApplication.recently_recorded_client_verifications(search_options)
  end

  def pending_loan_file_generation(search_options = {})
    LoanApplication.pending_loan_file_generation(search_options)
  end

  # Update action completed (background tasks)

  def dedupe_screened(*loan_application_ids)
  end

  def credit_bureau_request_generated(*loan_application_ids)
  end

  # Lists by status

  # General purpose search
  def search(search_options = {})
    LoanApplication.search(search_options)
  end

  def newly_created(search_options = {})
  end

  def completed_dedupe(search_options = {})
  end

  def completed_dedupe_review(search_options = {})
  end

  def completed_credit_bureau_rating(search_options = {})
  end

  def completed_CPV(search_options={})
  end

  def completed_authorization(search_options = {})
    LoanApplication.completed_authorization(search_options)
  end

end

# A loan application is created either for existing clients or new loan applicants
# Once created, it is subjected to a de-dupe check across new applicants and clients
# If it clears the de-dupe, requests are generated for checking with the credit bureau
# The loan applications are rated on the response from the credit bureau
# The loan applications may then be approved or rejected for fresh loans
# Approved loan applications progress to center creation
## CPV must be completed
## CGT is conducted for the center
## GRT is conducted at the center
# For loan applications that clear CGT at a center, a loan file is created
## For loan file creation, a scheduled disbursal date, a first payment date must be assigned
# The loan file travels to FINOPS
# FINOPS subjects the loan file to health check
# When health check is cleared, loans may be made
