class LoanFiles < Application

  def index
    render :index
  end

  def get_loan_applications
    @branch_id = params['branch_id'] ? params['branch_id'] : nil
    @center_id = params['center_id'] ? params['center_id'] : nil
    facade = LoanApplicationsFacade.new(session.user)
    @loan_applications_pending_loan_file_generation = facade.pending_loan_file_generation({:at_branch_id=>@branch_id})
     
    render :loan_file_generation
  end

  def loan_file_generation
    if request.method == :post
      loan_applications = params['selected'].keys
      laf = LoanApplicationFacade.new()
      if params['loan_file'] and not param['loan_file'].nil?
        loan_file = laf.get_loan_file(params['loan_file'])    
        laf.add_to_loan_file(on_loan_file, params['by_staff'], params['on_date'], *loan_applications)
      else
        loan_file = laf.create_loan_file(at_branch, at_center, for_cycle_number, by_staff, on_date, *loan_applications)
      end
    end
  end

  def loan_files_for_health_checkup
    @errors = {}
    if params[:branch_id] && params[:branch_id].empty?
      @errors["Loan File"] = "Please select a branch"
    elsif params[:center_id] && params[:center_id].empty?
      @errors["Loan File"] = "Please select center"
    end
    @branch = Branch.get(params[:branch_id].to_i) 
    @center = Center.get(params[:center_id].to_i)
    for_cycle_number = CenterCycle.get_current_center_cycle(@center.id)
    facade = LoanApplicationsFacade.new(session.user)
    @loan_files_at_center_at_branch_for_cycle = facade.locate_loan_files_at_center_at_branch_for_cycle(@branch.id, @center.id, for_cycle_number)
    render :health_checkup
  end

  def record_health_check_status
    if request.method == :post
      @errors = {}
      loan_files =  params[:loan_files].keys
      loan_files.each do |loan_file_id|
        loan_file = LoanFile.get(loan_file_id)
        health_status_remark = params[:loan_files][loan_file_id][:health_status_remark]
        status = loan_file.update(:health_check_status => Constants::Status::HEALTH_CHECK_APPROVED, :health_status_remark => health_status_remark) if params[:loan_files][loan_file_id][:health_check_status] == 'on'
        @errors[loan_file.id] = loan_file.errors if status == false
      end
    end
    @branch = Branch.get(params[:branch_id].to_i)
    @center = Center.get(params[:center_id].to_i)
    for_cycle_number = CenterCycle.get_current_center_cycle(@center.id)
    facade = LoanApplicationsFacade.new(session.user)
    @loan_files_at_center_at_branch_for_cycle = facade.locate_loan_files_at_center_at_branch_for_cycle(@branch.id, @center.id, for_cycle_number)
    render :health_checkup
  end

end
