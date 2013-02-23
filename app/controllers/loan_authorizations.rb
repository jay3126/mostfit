class LoanAuthorizations < Application

  def index
    get_branch_and_center(params)
    get_pending_and_completed_auth(params)
    render :authorizations
  end
  
  def pending_authorizations
    get_branch_and_center(params)
    unless params[:flag] == 'true'
      if @branch_id.nil?
        @errors << "No branch selected"
      elsif @center_id.nil?
        @errors << "No center selected"
      else
        get_pending_and_completed_auth(params)
      end
    end
    render :authorizations
  end

  def record_authorizations
    # INITIALIZING VARIABLES USED THROUGHOUT

    get_branch_and_center(params)

    # GATEKEEPING

    by_staff = params[:by_staff_id]
    on_date = params[:performed_on]
    lap_ids = []
    # VALIDATIONS

    @errors << "Staff member is not selected " if by_staff.blank?
    @errors << "Please select loan authorization status for atleast one loan application" if params[:status].blank?
    @errors << "Created on date must not be future date" if Date.parse(on_date) > Date.today

    # OPERATIONS PERFORMED

    if @errors.blank?
      params[:status].keys.each do |lap|
        begin
          authorization_status = params[:status][lap]
          override_reason = params[:override_reason][lap]
          loan_application = LoanApplication.get(lap)
          credit_bureau_status = loan_application.credit_bureau_status
          final_status = loan_applications_facade.check_loan_authorization_status(credit_bureau_status, authorization_status)
          #          raise Errors::DataError, "Authorized on date(#{on_date}) must not before credit bureau rated on date(#{loan_application.credit_bureau_rated_at.display})" if ((Date.parse(on_date) < Date.parse(loan_application.credit_bureau_rated_at.display)) rescue true)
          if final_status == Constants::Status::APPLICATION_APPROVED
            loan_applications_facade.authorize_approve(lap, by_staff, on_date)

          elsif final_status == Constants::Status::APPLICATION_OVERRIDE_APPROVED
            raise ArgumentError, "Please provide override reason" if override_reason.blank?
            loan_applications_facade.authorize_approve_override(lap, by_staff, on_date, override_reason)
           
          elsif final_status == Constants::Status::APPLICATION_REJECTED
            loan_applications_facade.authorize_reject(lap, by_staff, on_date)

          else
            raise ArgumentError, "Please provide override reason" if override_reason.blank?
            loan_applications_facade.authorize_reject_override(lap, by_staff, on_date, override_reason)
          end
          lap_ids << lap
        rescue => ex
          @errors << "An error has occured for Loan Application ID #{lap}: #{ex.message}"
        end
      end
    end

    # POPULATING RESPONSE AND OTHER VARIABLES
    unless lap_ids.blank?
      @success = "Loan Application ID: [#{lap_ids.flatten.join(', ')}] has successfully authorized"
    end
    get_pending_and_completed_auth(params)

    # RENDER/RE-DIRECT

    render :authorizations
  end


  private

  def get_branch_and_center(params)
    @errors = []
    @branch_id = params[:parent_location_id] && !params[:parent_location_id].empty? ? params[:parent_location_id] : nil
    @center_id = params[:child_location_id] && !params[:child_location_id].empty? ? params[:child_location_id] : nil
    @branch = location_facade.get_location(@branch_id) if @branch_id
    @center = location_facade.get_location(@center_id) if @center_id
    @user_id = session.user.id
  end

  def get_pending_and_completed_auth(params)
    @pending_authorizations = loan_applications_facade.pending_authorization(search_options(@branch_id, @center_id))
    @all_loan_applications = loan_applications_facade.get_all_loan_applications_for_branch_and_center({:at_branch_id => @branch_id, :at_center_id => @center_id})
  end

  def search_options(branch_id = nil, center_id = nil)
    options = {}
    options[:at_branch_id] = branch_id if branch_id
    options[:at_center_id] = center_id if center_id
    options
  end

end