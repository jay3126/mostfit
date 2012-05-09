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
    facade = LoanApplicationsFacade.new(session.user)

    # GATEKEEPING

    by_staff = params[:by_staff_id]
    on_date = params[:performed_on]
    

    # VALIDATIONS

    @errors << "Staff member is not selected " if by_staff.blank?
    @errors << "Please select authorization status " if params[:status].blank?

    # OPERATIONS PERFORMED

    if @errors.blank?
      params[:status].keys.each do |lap|
        begin
          authorization_status = params[:status][lap]
          override_reason = params[:override_reason][lap]
          loan_application = LoanApplication.get(lap)
          debugger
          credit_bureau_status = loan_application.credit_bureau_status
          final_status = facade.check_loan_authorization_status(credit_bureau_status, authorization_status)

          if final_status == Constants::Status::APPLICATION_APPROVED
            facade.authorize_approve(lap, by_staff, on_date)

          elsif final_status == Constants::Status::APPLICATION_OVERRIDE_APPROVED
            raise ArgumentError, "Please provide override reason" if override_reason.include?("Not overriden")
            facade.authorize_approve_override(lap, by_staff, on_date, override_reason)
           
          elsif final_status == Constants::Status::APPLICATION_REJECTED
            facade.authorize_reject(lap, by_staff, on_date)

          else
            raise ArgumentError, "Please provide override reason" if override_reason.include?("Not overriden")
            facade.authorize_reject_override(lap, by_staff, on_date, override_reason)
          end
        rescue => ex
          @errors << "An error has occured: #{ex.message}"
        end
      end
    end

    # POPULATING RESPONSE AND OTHER VARIABLES
    
    get_pending_and_completed_auth(params)

    # RENDER/RE-DIRECT

    render :authorizations
  end


  private

  def get_branch_and_center(params)
    @errors = []
    @center_id = params[:center_id] && !params[:center_id].empty? ? params[:center_id] : nil
    @branch_id = params[:branch_id] && !params[:branch_id].empty? ? params[:branch_id] : nil
    @center = Center.get(@center_id)
    @user_id = session.user.id
  end

  def get_pending_and_completed_auth(params)
    facade = LoanApplicationsFacade.new(session.user)
    @pending_authorizations = facade.pending_authorization(search_options(@branch_id, @center_id))
    @completed_authorizations = facade.completed_authorization(search_options(@branch_id, @center_id))
  end

  def search_options(branch_id = nil, center_id = nil)
    options = {}
    options[:at_branch_id] = branch_id if branch_id
    options[:at_center_id] = center_id if center_id
    options
  end

end