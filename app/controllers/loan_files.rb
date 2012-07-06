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

  # For generating loan
  def generate_loans(id)
    # INITIALIZATION
    @errors = []
    return NotFound unless params['id']
    @loan_file = LoanFile.get(id)
    raise NotFound unless @loan_file
    @center = BizLocation.get(@loan_file.at_center_id)
    @branch = BizLocation.get(@loan_file.at_branch_id)
    @clients = []

    # GATE-KEEPING
    if params[:loan]
      applied_on_date = params[:loan][:applied_on]
      scheduled_disbursal_date = params[:loan][:scheduled_disbursal_date]
      scheduled_first_payment_date = params[:loan][:scheduled_first_payment_date]
      applied_by_staff = params[:loan][:applied_by_staff_id]
      recorded_by_user = session.user.id
      clients = params[:clients]

      # VALIDATIONS
      @errors << "Applied on date must not be blank" if applied_on_date.blank?
      @errors << "Scheduled disbursal date must not be blank" if scheduled_disbursal_date.blank?
      @errors << "Scheduled first payment date must not be blank" if scheduled_first_payment_date.blank?
      @errors << "Applied by staff must not be blank" if applied_by_staff.blank?
      @errors << "Scheduled disbursal date must not before application date" if Date.parse(scheduled_disbursal_date) < Date.parse(applied_on_date)
      @errors << "Scheduled first payment date must not before application date" if Date.parse(scheduled_first_payment_date) < Date.parse(applied_on_date)
      @errors << "Scheduled first payment date must not before Scheduled disbursal date" if Date.parse(scheduled_first_payment_date) < Date.parse(scheduled_disbursal_date)
    end

    # need to refactor: get those clients only who are eligible
    @loan_file.loan_applications.each do |l|
      client = Client.get(l.client_id)
      not_eligible_client = client_facade.get_all_loans_for_counterparty(client)
      @clients << client if not_eligible_client.blank?
    end

    sc = clients.map{|k,v| k if v[:chosen]}.compact if clients
    @selected_clients = sc.blank? ? nil : sc

    if params[:loan]
      if @errors.blank?
        unless @selected_clients.blank?
          begin
            @loans = []
            message = nil
            @selected_clients.each do |client_id|
              params[:clients][client_id].delete(:chosen)
              lap = @loan_file.loan_applications(:client_id => client_id).first
              applied_money_amount = MoneyManager.get_money_instance_least_terms(lap.amount.to_i)
              raise NotFound, "loan product must not be blank for Cliend ID: #{client_id}" if params[:clients][client_id][:loan_product_id].blank?
              raise NotFound, "loan purpose must not be blank for Client ID: #{client_id}" if params[:clients][client_id][:loan_purpose].blank?
              loan_purpose = params[:clients][client_id][:loan_purpose]
              from_lending_product = LendingProduct.get(params[:clients][client_id][:loan_product_id])
              repayment_frequency = from_lending_product.repayment_frequency
              tenure = from_lending_product.tenure
              for_borrower = Client.get(client_id)
              administered_at_origin = lap.at_center_id
              accounted_at_origin = lap.at_branch_id
              loan = loan_facade.create_new_loan(applied_money_amount,repayment_frequency,tenure,from_lending_product,for_borrower,administered_at_origin,accounted_at_origin,applied_on_date,scheduled_disbursal_date,scheduled_first_payment_date,applied_by_staff,recorded_by_user, nil, loan_purpose)
              @loans.push(loan)
            end
            r = @loans.map{|l| l.saved?}
            if r.include?(false)
              message = {:error => "Loans cannot be saved"}
            else
              @loan_file.update(:health_check_status => Constants::Status::READY_FOR_DISBURSEMENT)
              loan_ids = @loans.map{|x| x.id}
              message = {:notice => "Successfully added loans with ids #{loan_ids.to_json}"}
            end
          rescue => ex
            message = {:error => "An error has occured: #{ex.message}"}
          end
        else
          message = {:error => "No clients selected"}
        end
      else
        message = {:error => @errors.flatten.join(', ')}
      end
      redirect url("loan_files/generate_loans/#{params['id']}"), :message => message
    else
      if @clients.include?(nil)
        redirect resource(@loan_file), :message => {:error => 'Cannot generate loans for this loan file because clients have not been created for certain loan applications'}
      else
        display([@center, @clients], "loan_files/generate_loans")
      end
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
    created_on = params[:created_on]
    scheduled_disbursal_date = params[:scheduled_disbursal_date]
    scheduled_first_payment_date = params[:scheduled_first_payment_date]
    created_by_staff_id = params[:created_by_staff_id]
    is_grt_marked = CenterCycle.is_grt_marked?(params[:child_location_id])

    @errors << "Staff member must not be blank" if created_by_staff_id.blank?
    @errors << "Please select atleast one loan application" unless params.key?('selected')
    @errors << "Created on date must not be future date" if Date.parse(created_on) > Date.today
    @errors << "Loan file cannot be generated because GRT is not passed for this center" unless is_grt_marked

    #record the loan file first
    #was any data actually sent ?
    if @errors.blank?
      @loan_applications = params['selected'].keys
      @branch_id = params[:parent_location_id] ? params[:parent_location_id] : nil
      @center_id = params[:child_location_id] ? params[:child_location_id] : nil
      @for_cycle_number = 1
      if params['loan_file_identifier'] and not params['loan_file_identifier'].nil?
        @loan_file = loan_applications_facade.locate_loan_file(params['loan_file_identifier'])
        loan_applications_facade.add_to_loan_file(@loan_file.loan_file_identifier, @branch_id, @center_id, @for_cycle_number, created_by_staff_id, created_on, *@loan_applications)
      else
        @loan_file = loan_applications_facade.create_loan_file(@branch_id, @center_id, @for_cycle_number,
          scheduled_disbursal_date, scheduled_first_payment_date,
          created_by_staff_id, created_on, *@loan_applications)
      end
    end
    get_data(params)

    render :loan_file_generation
  end

  def record_health_check_status
    # INITIALIZING VARIABLES USED THROUGHOUT
    @errors = []

    # GATE-KEEPING
    branch_id = get_param_value(:parent_location_id)
    center_id = get_param_value(:child_location_id)

    # VALIDATIONS
    unless params[:flag] == "true"
      @errors << "No branch selected" unless branch_id
      @errors << "No center selected" unless center_id
    end

    # FETCH RESPONSE VARIABLES FROM PRIVATE METHOD
    fetch_loan_files_for_branch_and_center(params)

    # OPERATION PERFORMED
    if @errors.blank? && !params[:loan_files].nil?
      loan_files =  params[:loan_files]
      loan_files.keys.each do |loan_file_id|
        loan_file = LoanFile.get(loan_file_id)
        remark_condition = loan_files[loan_file_id][:health_status_remark].blank? && !loan_file.health_status_remark.blank? || loan_files[loan_file_id][:health_status_remark]
        health_remark = remark_condition ? loan_files[loan_file_id][:health_status_remark] : loan_file.health_status_remark
        health_status = !loan_files[loan_file_id][:health_check_status].blank? ? loan_files[loan_file_id][:health_check_status] : loan_file.health_check_status
        pending_or_new_status = health_status == Constants::Status::HEALTH_CHECK_PENDING || health_status == Constants::Status::NEW_STATUS
        if pending_or_new_status
          if health_remark.blank?
            @errors << "Provide remark to Loan file pending for health checkup"
          else
            loan_file.update(:health_check_status => Constants::Status::HEALTH_CHECK_PENDING, :health_status_remark => health_remark )
          end
        else
          loan_file.update(:health_check_status => Constants::Status::HEALTH_CHECK_APPROVED, :health_status_remark => health_remark )
        end
      end
    end

    # RENDER/RE-DIRECT
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
      send_data(file.to_s, :filename => "loan_file_disbursement_sheet_#{loan_file.id}.pdf")
    else
      redirect :back
    end
  end

  def loan_files_list
    @loan_files = LoanFile.all(:at_branch_id => params[:at_branch_id], :at_center_id => params[:at_center_id], :health_check_status => params[:status])
    render :index
  end


  private

  def get_data(params)
    if params[:parent_location_id].blank?
      @errors["Loan File"] = "No branch selected"
    elsif params[:child_location_id].blank?
      @errors["Loan File"] = "No center selected"
    end
    @branch_id = params[:parent_location_id] ? params[:parent_location_id] : nil
    @center_id = params[:child_location_id] ? params[:child_location_id] : nil
    @center = location_facade.get_location(@center_id)
    @center_cycle_number = 1
    @loan_file = loan_applications_facade.locate_loan_file_at_center(@branch_id, @center_id, @center_cycle_number)
    @loan_applications_pending_loan_file_generation = loan_applications_facade.pending_loan_file_generation({:at_branch_id=>@branch_id, :at_center_id => @center_id})
    @loan_applications_added_to_loan_file = (not @loan_file.nil?) ? @loan_file.loan_applications : nil
  end

  def get_param_value(param_name_sym)
    param_value_str = params[param_name_sym]
    param_value = (param_value_str and (not (param_value_str.empty?))) ? param_value_str : nil
    param_value
  end

  def fetch_loan_files_for_branch_and_center(params)
    @branch =location_facade.get_location(params[:parent_location_id].to_i)
    @center = location_facade.get_location(params[:child_location_id].to_i)
    for_cycle_number = CenterCycle.get_current_center_cycle(@center.id)
    @loan_files_at_center_at_branch_for_cycle = loan_applications_facade.locate_loan_files_at_center_at_branch_for_cycle(@branch.id, @center.id, for_cycle_number)
  end

end
