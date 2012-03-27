# All operations on loan applications and underlying associations go through this facade
class LoanApplicationsFacade

  def initialize(user)
    @user = user
    @created_at = DateTime.now
  end

  # creation

  def create_for_client(client, loan_amount, at_branch, at_center, by_staff, on_date)
  end

  def create_for_new_applicant(new_application_info, loan_amount, at_branch, at_center, by_staff, on_date)
  end

  # General information
  def get_loan_application_status(loan_application_id)
  end

  def get_loan_application_info(loan_application_id)
  end

  # Rate suspect on de-dupe

  def rate_suspected_duplicate(loan_application_id)
  end
  
  # Confirm or clear suspect from de-dupe

  def confirm_duplicate(loan_application_id)
  end

  def confirm_not_duplicate(loan_application_id)
  end

  # Rate on credit bureau response

  def rate_by_credit_bureau_response(loan_application_id)
  end

  # Loan authorization

  def authorize_approve(loan_application_id, by_staff, on_date)
    LoanAuthorization.record_authorization(loan_application_id, Constants::Status::APPLICATION_APPROVED, by_staff, on_date, @user.id)
  end

  def authorize_approve_override(loan_application_id, by_staff, on_date, override_reason)
    LoanAuthorization.record_authorization(loan_application_id, Constants::Status::APPLICATION_OVERRIDE_APPROVED, by_staff, on_date, @user.id, override_reason)
  end

  def authorize_reject(loan_application_id,by_staff, on_date)
    LoanAuthorization.record_authorization(loan_application_id, Constants::Status::APPLICATION_REJECTED, by_staff, on_date, @user.id)
  end

  def authorize_reject_override(loan_application_id, by_staff, on_date, override_reason)
    LoanAuthorization.record_authorization(loan_application_id, Constants::Status::APPLICATION_OVERRIDE_REJECTED, by_staff, on_date, @user.id, override_reason)
  end

  # CPVs

  def record_CPV1_approved(loan_application_id, by_staff, on_date)
  end

  def record_CPV1_rejected(loan_application_id, by_staff, on_date)
  end

  def record_CPV2_approved(loan_application_id, by_staff, on_date)
  end

  def record_CPV2_rejected(loan_application_id, by_staff, on_date)
  end

  # Create loan file

  def create_loan_file(at_branch, at_center, by_staff, on_date, *loan_application_id)
  end

  def add_to_loan_file(on_loan_file, by_staff, on_date, *loan_application_id)
  end

  # Awaiting action

  def pending_dedupe(search_options = {})
  end

  def pending_credit_bureau_check(search_options = {})
  end

  def pending_authorization(search_options = {})
    LoanApplication.pending_authorization(search_options)
  end

  def pending_CPV(search_options = {})
  end

  # Update action completed (background tasks)

  def dedupe_screened(*loan_application_ids)
  end

  def credit_bureau_request_generated(*loan_application_ids)
  end

  # Lists by status

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
