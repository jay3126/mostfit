# All operations on loan applications and underlying associations go through this facade
class LoanApplicationsFacade

  def initialize(user)
    @user = user
    @created_at = DateTime.now
  end

  # creation

  def create_for_client(client, loan_amount, at_branch, at_center, for_cycle, by_staff, on_date)
    hash = client.to_loan_application + {
      :amount              => loan_amount,  #params[:clients][client_id][:amount],
      :created_by_staff_id => by_staff,     #params[:staff_member_id].to_i,
      :at_branch_id        => at_branch,    #params[:at_branch_id].to_i,
      :at_center_id        => at_center,    #params[:at_center_id].to_i,
      :created_by_user_id  => @user.id,      #session.user.id,
      :center_cycle_id     => for_cycle, #center_cycle.id,
      :created_on          => on_date       #created_on1
    }
    loan_application = LoanApplication.new(hash)
  end

  def create_for_new_applicant(new_application_info, loan_amount, at_branch, at_center, for_cycle, by_staff, on_date)
    hash = new_application_info + {
      :amount              => loan_amount,
      :at_branch_id        => at_branch,
      :at_center_id        => at_center,
      :center_cycle_id     => for_cycle,
      :created_by_staff_id => by_staff,
      :created_on          => on_date,
      :created_by_user_id  => @user.id
    }
    loan_application = LoanApplication.new(hash)
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

  # Rate on credit bureau response

  def rate_by_credit_bureau_response(loan_application_id, rating)
    loan_application = LoanApplication.get(loan_application_id)
    raise NotFound if loan_application.nil?
    loan_application.record_credit_bureau_response(rating)
  end

  # Loan authorization

  def authorize_approve(loan_application_id, by_staff, on_date)
    LoanApplication.record_authorization(loan_application_id, Constants::Status::APPLICATION_APPROVED, by_staff, on_date, @user.id)
  end

  def authorize_approve_override(loan_application_id, by_staff, on_date, override_reason)
    LoanApplication.record_authorization(loan_application_id, Constants::Status::APPLICATION_OVERRIDE_APPROVED, by_staff, on_date, @user.id, override_reason)
  end

  def authorize_reject(loan_application_id,by_staff, on_date)
    LoanApplication.record_authorization(loan_application_id, Constants::Status::APPLICATION_REJECTED, by_staff, on_date, @user.id)
  end

  def authorize_reject_override(loan_application_id, by_staff, on_date, override_reason)
    LoanApplication.record_authorization(loan_application_id, Constants::Status::APPLICATION_OVERRIDE_REJECTED, by_staff, on_date, @user.id, override_reason)
  end

  # CPVs

  def record_CPV1_approved(loan_application_id, by_staff, on_date)
    loan_application = LoanApplication.get(loan_application_id)
    raise NotFound if loan_application.nil?
    loan_application.record_CPV1_approved(by_staff, on_date, @user.id)
  end

  def record_CPV1_rejected(loan_application_id, by_staff, on_date)
    loan_application = LoanApplication.get(loan_application_id)
    raise NotFound if loan_application.nil?
    loan_application.record_CPV1_rejected(by_staff, on_date, @user.id)
  end

  def record_CPV2_approved(loan_application_id, by_staff, on_date)
    loan_application = LoanApplication.get(loan_application_id)
    raise NotFound if loan_application.nil?
    loan_application.record_CPV2_approved(by_staff, on_date, @user.id)
  end

  def record_CPV2_rejected(loan_application_id, by_staff, on_date)
    loan_application = LoanApplication.get(loan_application_id)
    raise NotFound if loan_application.nil?
    loan_application.record_CPV2_rejected(by_staff, on_date, @user.id)
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
    LoanApplication.create_loan_file(at_branch, at_center, for_cycle_number, scheduled_disbursal_date, scheduled_first_payment_date, by_staff, on_date, @user.id, *loan_application_id)
  end

  def add_to_loan_file(on_loan_file, at_branch, at_center, for_cycle_number, by_staff, on_date, *loan_application_id)
    LoanApplication.add_to_loan_file(on_loan_file, at_branch, at_center, for_cycle_number, by_staff, on_date, @user.id, *loan_application_id)
  end

  # Recently Added Loan Applications
  def recently_added_applicants(search_options = {})
    search_options.merge!({:created_by_user_id => @user.id})
    LoanApplication.recently_created_new_loan_applicants(search_options)
  end

  def recently_added_applications_for_existing_clients(search_options = {})
    search_options.merge!({:created_by_user_id => @user.id})
    LoanApplication.recently_created_new_loan_applications_from_existing_clients(search_options)
  end

  # returns all loan applications which are pending for de-dupe process
  def self.pending_dedupe
    LoanApplication.pending_dedupe
  end

  # returns all loan applications which has status not_duplicate
  def self.not_duplicate(search_options = {})
    search_options.merge!({:created_by_user_id => @user.id})
    LoanApplication.not_duplicate(search_options)
  end

  # Return all loan applications which has status suspected_duplicate
  def suspected_duplicate(search_options = {})
    search_options.merge!({:created_by_user_id => @user.id})
    LoanApplication.suspected_duplicate(search_options)
  end

  # Return all loan applications which has status cleared_not_duplicate and confirmed_duplicate
  def clear_or_confirm_duplicate(search_options = {})
    search_options.merge!({:created_by_user_id => @user.id})
    LoanApplication.clear_or_confirm_duplicate(search_options)
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
    search_options.merge!({:created_by_user_id => @user.id})
    LoanApplication.pending_overlap_report_request_generation(search_options)
  end

  def pending_authorization(search_options = {})
    search_options.merge!({:created_by_user_id => @user.id})
    LoanApplication.pending_authorization(search_options)
  end

  def pending_CPV(search_options = {})
    search_options.merge!({:created_by_user_id => @user.id})
    LoanApplication.pending_verification(search_options)
  end

  def pending_loan_file_generation(search_options = {})
    search_options.merge!({:created_by_user_id => @user.id})
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
