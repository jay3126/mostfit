class LoanAuthorizations < Application

  def index
    render :authorizations
  end

  def new
    only_provides :html
    @loan_authorization = LoanAuthorization.new
    display @loan_authorization
  end

  def create
    @loan_authorization = LoanAuthorization.new
    if @loan_authorization.save
      redirect resource(@loan_authorization), :message => {:notice => "Loan authorization successfully created"}
    else
      message[:error] = "Loan authorization failed to be created"
      render :new
    end
  end
  
  def get_data(params)
    @center_id = params[:center_id] && !params[:center_id].empty? ? params[:center_id] : nil
    @branch_id = params[:branch_id] && !params[:branch_id].empty? ? params[:branch_id] : nil
    @center = Center.get(@center_id)
    @user_id = session.user.id
    @loan_application_pending_authorization = LoanApplication.pending_authorization(search_options(@branch_id, @center_id))
    facade = LoanApplicationsFacade.new(session.user)
    @recent_authorization = facade.completed_authorization(search_options(@branch_id, @center_id))
  end

  def pending_authorizations
    @errors = {}
    get_data(params)
    if @branch_id.nil?
      @errors['Search Form'] = "No branch selected"
    else
      @show_pending = true
      facade = LoanApplicationsFacade.new(session.user)
      @pending_authorization = facade.pending_authorization(search_options(@branch_id, @center_id))
    end
    render :authorizations
  end

  def record_authorizations
    @errors = {}
    get_data(params)
    @center = Center.get(@center_id)
    facade = LoanApplicationsFacade.new(session.user)
    @pending_authorization = facade.pending_authorization(search_options(@branch_id, @center_id))
    by_staff = params[:by_staff_id]
    on_date = params[:performed_on]
    override_reason = params[:override_reason]
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
    @show_pending = true
    render :authorizations
  end

  def recent_authorization
    get_data(params)
    facade = LoanApplicationsFacade.new(session.user)
    @recent_authorization = facade.completed_authorization(search_options(@branch_id, @center_id))
  end

  def search_options(branch_id = nil, center_id = nil)
    options = {}
    options[:at_branch_id] = branch_id if branch_id
    options[:at_center_id] = center_id if center_id
    options
  end

end