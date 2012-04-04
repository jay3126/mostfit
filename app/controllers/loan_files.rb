class LoanFiles < Application

  def index
    render :loan_file_generation
  end

  def get_data(params)
    @branch_id = params['branch_id'] ? params['branch_id'] : nil
    @center_id = params['center_id'] ? params['center_id'] : nil
    @center = Center.get(@center_id)
    @center_cycle_number = 1
    facade = LoanApplicationsFacade.new(session.user)
    @loan_file = facade.locate_loan_file_at_center(@branch_id, @center_id, @center_cycle_number)
    @loan_applications_pending_loan_file_generation = facade.pending_loan_file_generation({:at_branch_id=>@branch_id})
    @loan_applications_added_to_loan_file = (not @loan_file.nil?) ? @loan_file.loan_applications : nil
  end

  def pending_loan_file_generation
    get_data(params)
    render :loan_file_generation
  end

  def record_loan_file
  @errors = {}

  #record the loan file first
  #was any data actually sent ?
  if params.key?('selected')
    @loan_applications = params['selected'].keys
    @branch_id = params['branch_id'] ? params['branch_id'] : nil
    @center_id = params['center_id'] ? params['center_id'] : nil
    @for_cycle_number = 1

    laf = LoanApplicationsFacade.new(session.user)
    created_by_staff_id = params['created_by_staff_id']
    if created_by_staff_id.nil?
      @errors['Loan File Generation'] = "No staff member selected! "
      get_data(params)
      render :loan_file_generation
    end

    created_on = params['created_on']
    scheduled_disbursal_date = params['scheduled_disbursal_date']
    scheduled_first_payment_date = params['scheduled_first_payment_date']

    if params['loan_file_identifier'] and not params['loan_file_identifier'].nil?
      @loan_file = laf.locate_loan_file(params['loan_file_identifier'])
    
      laf.add_to_loan_file(@loan_file.loan_file_identifier, @branch_id, @center_id, @for_cycle_number, created_by_staff_id, created_on, *@loan_applications)
    else
      @loan_file = laf.create_loan_file(@branch_id, @center_id, @for_cycle_number, 
                                     scheduled_disbursal_date, scheduled_first_payment_date, 
                                     created_by_staff_id, created_on, *@loan_applications)
    end
  else
    @errors['Loan File Generation'] = "No loan applications selected!"
  end
  get_data(params)
  if @errors.empty?
    @show_recorded = true
  end

  render :loan_file_generation
  end

end
