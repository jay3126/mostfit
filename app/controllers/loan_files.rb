class LoanFiles < Application

  def index
    @loan_files = LoanFile.all
    render :index
  end

  def show(id)
    @loan_file = LoanFile.get(id)
    raise NotFound unless @loan_file
    display @loan_file
  end
  
  def get_data(params)
    if params[:branch_id] && params[:branch_id].empty?
      @errors["Loan File"] = "No branch selected"
    elsif params[:center_id] && params[:center_id].empty?
      @errors["Loan File"] = "No center selected"
    end
    @branch_id = params['branch_id'] ? params['branch_id'] : nil
    @center_id = params['center_id'] ? params['center_id'] : nil
    @center = Center.get(@center_id)
    @center_cycle_number = 1
    facade = LoanApplicationsFacade.new(session.user)
    @loan_file = facade.locate_loan_file_at_center(@branch_id, @center_id, @center_cycle_number)
    @loan_applications_pending_loan_file_generation = facade.pending_loan_file_generation({:at_branch_id=>@branch_id, :at_center_id => @center_id})
    @loan_applications_added_to_loan_file = (not @loan_file.nil?) ? @loan_file.loan_applications : nil
  end
  
  #for generating 
  def generate_loans(id)
    return NotFound unless params['id'] 
    @loan_file = LoanFile.get(id)
    raise NotFound unless @loan_file
    @center = Center.get(@loan_file.at_center_id)
    @clients = @loan_file.loan_applications.collect {|l| Client.get(l.client_id) if not l.client_id.nil?}  
    if @clients.include?(nil)
      redirect resource(@loan_file), :message => {:error => 'Cannot generate loans for this loan file because clients have not been created for certain loan applications'} 
    else
      display([@center, @clients], "data_entry/loans/bulk_form")
    end
  end

  def loan_file_generation
    render :loan_file_generation
  end 

  def pending_loan_file_generation
    @errors = {}
    get_data(params)
    render :loan_file_generation
  end

  def record_loan_file
    @errors = []
    laf = LoanApplicationsFacade.new(session.user)
    created_on = params['created_on']
    scheduled_disbursal_date = params['scheduled_disbursal_date']
    scheduled_first_payment_date = params['scheduled_first_payment_date']
    created_by_staff_id = params['created_by_staff_id']
    @errors << "No staff member selected " if created_by_staff_id.blank?
    @errors << "No loan application selected" unless params.key?('selected')
    #record the loan file first
    #was any data actually sent ?
    if @errors.blank?
      @loan_applications = params['selected'].keys
      @branch_id = params['branch_id'] ? params['branch_id'] : nil
      @center_id = params['center_id'] ? params['center_id'] : nil
      @for_cycle_number = 1
      if params['loan_file_identifier'] and not params['loan_file_identifier'].nil?
        @loan_file = laf.locate_loan_file(params['loan_file_identifier'])
        laf.add_to_loan_file(@loan_file.loan_file_identifier, @branch_id, @center_id, @for_cycle_number, created_by_staff_id, created_on, *@loan_applications)
      else
        @loan_file = laf.create_loan_file(@branch_id, @center_id, @for_cycle_number,
          scheduled_disbursal_date, scheduled_first_payment_date,
          created_by_staff_id, created_on, *@loan_applications)
      end
    end
    get_data(params)

    render :loan_file_generation
  end

  def loan_files_for_health_checkup
    @errors = {}
    if params[:branch_id] && params[:branch_id].empty?
      @errors["Loan File"] = "No branch selected"
    elsif params[:center_id] && params[:center_id].empty?
      @errors["Loan File"] = "No center selected"
    end
    fetch_loan_files_for_branch_and_center(params)
  end

  def record_health_check_status
    @errors = {}
    fetch_loan_files_for_branch_and_center(params)
    loan_files =  params[:loan_files].keys
    loan_files.each do |loan_file_id|
      loan_file = LoanFile.get(loan_file_id)
      remark_condition = params[:loan_files][loan_file_id][:health_status_remark].blank? && !loan_file.health_status_remark.blank? || params[:loan_files][loan_file_id][:health_status_remark]
      health_remark = remark_condition ? params[:loan_files][loan_file_id][:health_status_remark] : loan_file.health_status_remark
      health_status = !params[:loan_files][loan_file_id][:health_check_status].blank? ? params[:loan_files][loan_file_id][:health_check_status] : loan_file.health_check_status 
      pending_or_new_status = health_status == Constants::Status::HEALTH_CHECK_PENDING || health_status == Constants::Status::NEW_STATUS
      if pending_or_new_status
        if health_remark.blank?
          @message = "Provide remark to Loan file pending for health checkup"
        else
          loan_file.update(:health_check_status => Constants::Status::HEALTH_CHECK_PENDING, :health_status_remark => health_remark )
        end
      else
        loan_file.update(:health_check_status => Constants::Status::HEALTH_CHECK_APPROVED, :health_status_remark => health_remark )
      end
    end
    @errors["Loan File"] = @message unless @message.blank?

    render :health_checkup
  end

  def generate_disbursement_labels
    loan_file = LoanFile.get params[:id]
    raise NotFound unless loan_file
    file = loan_file.generate_disbursement_labels_pdf
    if file
      send_data(file.to_s, :filename => "disbursement_labels_#{loan_file.id}.pdf")
    else
      redirect :back
    end
  end

  def generate_disbursement_sheet
    loan_file = LoanFile.get params[:id]
    raise NotFound unless loan_file
    file = loan_file.loan_file_generate_disbursement_pdf
    if file
      send_data(file.to_s, :filename => "lon_file_disbursement_sheet_#{loan_file.id}.pdf")
    else
      redirect :back
    end
  end

  private

  def fetch_loan_files_for_branch_and_center(params)
    @branch = Branch.get(params[:branch_id].to_i)
    @center = Center.get(params[:center_id].to_i)
    for_cycle_number = CenterCycle.get_current_center_cycle(@center.id)
    facade = LoanApplicationsFacade.new(session.user)
    @loan_files_at_center_at_branch_for_cycle = facade.locate_loan_files_at_center_at_branch_for_cycle(@branch.id, @center.id, for_cycle_number)
    render :health_checkup
  end

end
