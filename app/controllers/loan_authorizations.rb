class LoanAuthorizations < Application

  def index
    get_branch_and_center(params)
    get_pending_and_completed_auth(params)
    render :authorizations
  end
  
  def pending_authorizations
    get_branch_and_center(params)
    if @branch_id.nil?
      @errors['Search Form'] = "No branch selected"
    else
      get_pending_and_completed_auth(params)
    end
    render :authorizations
  end

  def record_authorizations
    get_branch_and_center(params)
    facade = LoanApplicationsFacade.new(session.user)
    by_staff = params[:by_staff_id]
    on_date = params[:performed_on]
    override_reason = params[:override_reason]
    if by_staff.empty?
      @errors['Loan Authorizations'] = "Staff member is not selected"
    end
    if params.key?('status')
      params[:status].keys.each do |lap|
        status = params[:status][lap]
        if status == Constants::Status::APPLICATION_APPROVED
          facade.authorize_approve(lap, by_staff, on_date)

        elsif status == Constants::Status::APPLICATION_OVERRIDE_APPROVED
          facade.authorize_approve_override(lap, by_staff, on_date, override_reason)
           
        elsif status == Constants::Status::APPLICATION_REJECTED
          facade.authorize_reject(lap, by_staff, on_date)

        else
          facade.authorize_reject_override(lap, by_staff, on_date, override_reason)
        end
      end
    else
      @errors['Loan Authorizations'] = "No data was passed!"
    end
    get_pending_and_completed_auth(params)
    render :authorizations
  end

  private

  def get_branch_and_center(params)
    @errors = {}
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