class LoanApplications < Application

  def index
    render
  end

  def show(id)
    @loan_app = LoanApplication.get(id)
    raise NotFound unless @loan_app
    display @loan_app
  end

  def bulk_upload_loan_applications
    render
  end

  def upload_loan_applications
    @errors = []

    # VALIDATIONS
    @errors << "Please select file" if params[:file].blank?
    @errors << "Invalid file selection (Accepts .xls extension file only)" if params[:file][:content_type] && params[:file][:content_type] != "application/vnd.ms-excel"
    if @errors.blank?
      begin
        filename = params[:file][:filename]
        xls_folder = File.join("#{Merb.root}/public/uploads", "bulk_upload_loan_applications", "uploaded_xls")
        FileUtils.mkdir_p(xls_folder)
        xls_filepath = File.join(xls_folder, filename)
        FileUtils.mv(params[:file][:tempfile].path, xls_filepath)
        
        csv_folder = File.join("#{Merb.root}/public/uploads", "bulk_upload_loan_applications", "converted_csv")
        FileUtils.mkdir_p(csv_folder)
        FileUtils.rm_rf("#{csv_folder}/.")
        csv_filepath = File.join(csv_folder, filename)

        User.convert_xls_to_csv(xls_filepath, csv_filepath)
        
      rescue => ex
        @errors << ex.message
      end
    end
    render :bulk_upload_loan_applications
  end

  # Only List all clients under selected center
  def bulk_new
    # INITIALIZING VARIABLES USED THROUGHOUT
    @errors = []

    # GATEKEEPING
    branch_id = get_param_value(:parent_location_id)
    center_id = get_param_value(:child_location_id)
    @branch = branch_id ? location_facade.get_location(branch_id) : nil
    @center = center_id ? location_facade.get_location(center_id) : nil
    
    # VALIDATION
    unless params[:flag] == 'true'
      @errors << "No branch was selected" unless branch_id
      @errors << "No center was selected" unless center_id
    end

    # OPERATIONS PERFORMED
    if @errors.empty?
      begin
        center_cycle_number = loan_applications_facade.get_current_center_cycle_number(center_id)
        fetch_existing_clients_for_new_loan_application(center_id, center_cycle_number) if center_cycle_number > 0
      rescue => ex
        @errors << "An error has occurred: #{ex.message}"
      end
    end

    # POPULATING RESPONSE AND OTHER VARIABLES
    @all_loan_applications = loan_applications_facade.get_all_loan_applications_for_branch_and_center({:at_branch_id => branch_id, :at_center_id => center_id})

    # RENDER/RE-DIRECT
    render
  end

  # Bulk addition of clients to loan applications
  def list
    # INITIALIZATIONS & GATE-KEEPING
    message = {}
    @errors = []
    selected = 0
    branch_id = params[:parent_location_id]
    center_id = params[:child_location_id]
    @branch = location_facade.get_location(branch_id) if branch_id
    @center = location_facade.get_location(center_id) if center_id
    by_staff = params[:staff_member_id]
    created_on = params[:created_on]
    center_cycle_number = loan_applications_facade.get_current_center_cycle_number(center_id)
    clients = params[:clients]

    # VALIDATIONS
    @errors << "No client is aligible to apply for New Loan Application" if clients.blank?
    @errors << "Please select a Staff Member" if by_staff.blank?
    @errors << "Please select a created on date" if created_on.blank?
    @errors << "Created on date must not be future date" if Date.parse(created_on) > Date.today

    # OPERATIONS-PERFORMED
    if @errors.blank?
      client_ids = clients.keys
      client_ids.each do |client_id|
        begin
          selected += 1 unless clients[client_id][:selected].blank?
          loan_amount_str = clients[client_id][:amount]
          loan_money_amount = MoneyManager.get_money_instance(loan_amount_str) if loan_amount_str
          client = Client.get(client_id)
          loan_application = loan_applications_facade.create_for_client(loan_money_amount, client, clients[client_id][:amount].to_i, branch_id.to_i, center_id.to_i, center_cycle_number, by_staff.to_i, created_on) if clients[client_id][:selected] == "on"
          if loan_application.save == false
            @errors << loan_application.errors.first.to_s
          end
        rescue => ex
          @errors << ex.message
        end
      end
      fetch_existing_clients_for_new_loan_application(center_id, center_cycle_number)
      @errors << "Please select atleast one client" if selected.eql?(0)
    end

    @all_loan_applications = loan_applications_facade.get_all_loan_applications_for_branch_and_center({:at_branch_id => branch_id, :at_center_id => center_id})
    if @errors.blank?
      message[:notice] = "Successfully added Existing Clients as New Loan Applicant"
    else
      message[:error] = @errors.flatten.join(', ')
    end
    redirect resource(:loan_applications, :bulk_new, :parent_location_id => branch_id, :child_location_id => center_id ), :message => message
  end

  # this function is responsible for creating new loan applications for new loan applicants a.k.a. clients that do not exist in the system 
  def bulk_create
    branch_id = params[:parent_location_id]
    center_id = params[:child_location_id]
    @branch = location_facade.get_location(branch_id) if branch_id
    @center = location_facade.get_location(center_id) if center_id
    @message = {:error => []}

    unless params[:flag] == 'true'
      if branch_id.blank?
        @message[:error] << "No branch selected"
      elsif center_id.blank?
        @message[:error] << "No center selected"
      end
    end
    @all_loan_applications = loan_applications_facade.get_all_loan_applications_for_branch_and_center({:at_branch_id => branch_id, :at_center_id => center_id})
    render :bulk_create
  end

  def bulk_create_loan_applicant
    # INITIALIZING VARIABLES USED THROUGHTOUT
    @message = {:error => [], :notice => []}
    branch_id = params[:parent_location_id]
    center_id = params[:child_location_id]
    @branch = location_facade.get_location(branch_id) if branch_id
    @center = location_facade.get_location(center_id) if center_id

    # GATE-KEEPING
    name = params[:loan_application][:client_name]
    guarantor_name = params[:loan_application][:client_guarantor_name]
    guarantor_relationship = params[:loan_application][:client_guarantor_relationship]
    dob = params[:client_dob]
    age_as_on = params[:age_as_on]
    age_as_on_date = params[:age_as_on_date]
    reference1 = params[:loan_application][:client_reference1]
    reference2 = params[:loan_application][:client_reference2]
    address = params[:loan_application][:client_address]
    state = params[:loan_application][:client_state]
    pincode = params[:loan_application][:client_pincode]
    created_by = params[:loan_application][:created_by_staff_id]
    created_on = params[:created_on]
    center_cycle_number = loan_applications_facade.get_current_center_cycle_number(center_id)
    loan_amount_str = params[:loan_application][:amount]

    no_age_parameter = (dob.blank? && (age_as_on.blank? || age_as_on_date.blank?))
    # Match format of client reference1 and reference2, it should allow only alphanumeric value
    format_reference1 = /^[A-Za-z0-9]+$/
    format_reference2 = /^[A-Za-z0-9]+$/

    unless reference1.blank?
      is_reference1_format_matched = format_reference1.match reference1.strip
      @message[:error] << "Reference-1 must be alphanumeric(allowed only: a-z, A-Z, 0-9)" if is_reference1_format_matched.nil?
    end

    unless reference2.blank?
      is_reference2_format_matched = format_reference2.match reference2.strip
      @message[:error] << "Reference-2 must be alphanumeric(allowed only: a-z, A-Z, 0-9)" if is_reference2_format_matched.nil?
    end
    
    # VALIDATIONS
    @message[:error] << "Applicant name must not be blank" if name.blank?
    @message[:error] << "Guarantor name must not be blank" if guarantor_name.blank?
    @message[:error] << "Guarantor relationship must not be blank" if guarantor_relationship.blank?
    @message[:error] << "Either Date of birth  or Age As ON field is manadatory" if no_age_parameter
    @message[:error] << "Either Ration card or Reference 2 is mandatory" if (reference1.blank? && reference2.blank?)
    @message[:error] << "Applied for amount must not be blank" if loan_amount_str.blank?
    @message[:error] << "Address name must not be blank" if address.blank?
    @message[:error] << "Pincode name must not be blank" if pincode.blank?
    @message[:error] << "State name must not be blank" if state.blank?
    @message[:error] << "Created by name must not be blank" if created_by.blank?
    @message[:error] << "Created on date must not be future date" if Date.parse(created_on) > Date.today


    unless no_age_parameter
      if dob.blank?
        if is_number?(age_as_on)
          client_age_as_on = age_as_on
          client_age_as_on_date = age_as_on_date
          client_dob = nil
        else
          @message[:error] << "Age as on is not valid"
        end
      else
        client_age_as_on = nil
        client_age_as_on_date = nil
        client_dob = dob
      end
    end

    # OPERATIONS-PERFORMED
    if @message[:error].blank?
      if request.method == :post
        loan_money_amount = MoneyManager.get_money_instance(loan_amount_str) if loan_amount_str
        loan_amount = loan_money_amount.amount.to_i
        loan_amount_currency = loan_money_amount.currency
        params[:loan_application][:client_pincode] = trim_lead(pincode, "0")
        params[:loan_application][:amount] = loan_amount
        params[:loan_application][:currency] = loan_amount_currency
        params[:loan_application][:client_reference1] = params[:loan_application][:client_reference1].strip
        params[:loan_application][:client_reference2] = params[:loan_application][:client_reference2].strip
        params[:loan_application] = params[:loan_application] + {:client_age_as_on => client_age_as_on, :client_age_as_on_date => client_age_as_on_date, :client_dob => client_dob, :created_on => created_on, :center_cycle_id => center_cycle_number, :created_by_user_id => session.user.id}
        @loan_application = LoanApplication.new(params[:loan_application])

        if @loan_application.save
          @message[:notice] = "The Loan Application has been successfully saved"
        else
          @message[:error] = @loan_application.errors.to_a.flatten.join(', ')
        end
      end
    else
      @message[:error] = @message[:error].flatten.join(', ')
    end

    # POPULATING RESPONSE AND OTHER VARIABLES
    @loan_application = LoanApplication.new(params[:loan_application])
    @all_loan_applications = loan_applications_facade.get_all_loan_applications_for_branch_and_center({:at_branch_id => branch_id, :at_center_id => center_id, :center_cycle_id => center_cycle_number})

    # RENDER/RE-DIRECT
    if @message[:error].blank?
      redirect resource(:loan_applications, :bulk_create, :parent_location_id => branch_id, :child_location_id => center_id ), :message => {:notice => @message[:notice].to_s}
    else
      render :template => 'loan_applications/bulk_create'
    end
  end

  def suspected_duplicates
    branch_id = params[:parent_location_id]
    center_id = params[:child_location_id]
    @branch = location_facade.get_location(branch_id) if branch_id
    @center = location_facade.get_location(center_id) if center_id
    @errors = []
    unless params[:flag] == 'true'
      if branch_id.blank?
        @errors << "No branch selected"
      end
    end
    get_de_dupe_loan_applications
    render :suspected_duplicates
  end

  def record_suspected_duplicates
    # INITIALIZING VARIABLES USED THROUGHOUT
    result = nil
    message = {}
    @errors = []

    # GATE-KEEPING
    staff_member_id = get_param_value(:staff_member_id)
    clear_or_confirm_duplicate = get_param_value(:clear_or_confirm_duplicate)
    created_on = params[:created_on]

    # VALIDATIONS
    @errors << 'Please select Staff member' unless staff_member_id
    @errors <<  'Please select Action either Cleared not duplicate or Confirm duplicate' unless clear_or_confirm_duplicate
    @errors << "Created on date must not be future date" if Date.parse(created_on) > Date.today

    # POPULATING RESPONSE AND OTHER VARIABLES
    get_de_dupe_loan_applications

    # OPERATIONS PERFORMED
    if @errors.empty?
      clear_or_confirm_duplicate.keys.each do |lap_id|
        begin
          loan_application = LoanApplication.get(lap_id)
          client_verification = loan_application.client_verifications.all(:verification_type => Constants::Verification::CPV2, :verification_status=>Constants::Verification::VERIFIED_ACCEPTED).last
          cpv2_approved_on_date = client_verification.verified_on_date
          unless cpv2_approved_on_date.blank?
            raise Errors::DataError, "dedupe processed on date (#{created_on}) must not before cpv2 approval date(#{cpv2_approved_on_date})" if ((Date.parse(created_on) < cpv2_approved_on_date) rescue true)
          end
          if  clear_or_confirm_duplicate[lap_id].include?('clear')
            result = loan_applications_facade.set_cleared_not_duplicate(lap_id)
          elsif clear_or_confirm_duplicate[lap_id].include?('confirm')
            result = loan_applications_facade.set_confirm_duplicate(lap_id)
          end
          if result
            message[:notice] = "Loan application has been updated successfully"
          else
            message[:error] = @errors.flatten.join(', ')
          end
        rescue => ex
          message[:error] = "An error has occurred for Loan Application ID #{lap_id}: #{ex.message}"
        end
 
      end
      # RENDER/RE-DIRECT
      if @center.blank?
        redirect resource(:loan_applications, :suspected_duplicates, :parent_location_id => @branch.id), :message => message
      else
        redirect resource(:loan_applications, :suspected_duplicates, :parent_location_id => @branch.id, :child_location_id => @center.id), :message => message
      end
    else
      render :suspected_duplicates
    end
    
  end

  def edit
    @loan_application = LoanApplication.get(params[:id])
    raise NotFound unless @loan_application
    display @loan_application
  end

  def update
    # INITIALIZATIONS
    @errors = []
    message = {}
    is_crucial_info_updated = false
    @loan_application = LoanApplication.get(params[:id])

    # GATE-KEEPING
    client_name             = params[:loan_application][:client_name]
    client_dob              = params[:loan_application][:client_dob]
    client_reference1       = params[:loan_application][:client_reference1]
    client_reference2       = params[:loan_application][:client_reference2]
    client_reference2_type  = params[:loan_application][:client_reference2_type]
    client_dob              = Date.parse(client_dob) unless client_dob.blank?
    client_reference2_type  = client_reference2_type.to_sym unless client_reference2_type.blank?

    # Credit Bureau File Creation for enquiry Resubmission of data when crucial fields are changed, like name, dob and ID details
    crucial_info_changed = (client_name != @loan_application.client_name || client_dob != @loan_application.client_dob || client_reference1 != @loan_application.client_reference1 || client_reference2 != @loan_application.client_reference2 || client_reference2_type != @loan_application.client_reference2_type)

    # remove leading and trailing spaces from reference-1 and reference-2
    params[:loan_application][:client_reference1] = params[:loan_application][:client_reference1].strip
    params[:loan_application][:client_reference2] = params[:loan_application][:client_reference2].strip

    loan_money_amount = MoneyManager.get_money_instance(params[:loan_application][:amount])
    loan_amount = loan_money_amount.amount.to_i
    loan_amount_currency = loan_money_amount.currency
    params[:loan_application][:amount] = loan_amount
    params[:loan_application][:currency] = loan_amount_currency

    begin
      loan_application = @loan_application.update(params[:loan_application])
      message = {:notice => "Loan application updated succesfully"}
      if crucial_info_changed && @loan_application.status != Constants::Status::LOAN_FILE_GENERATED_STATUS
        @loan_application.resubmit_loan_application(params[:loan_application])
        is_crucial_info_updated = true
      end
    rescue => ex
      @errors << "An error has occured: #{ex.message}"
      message = {:error => @errors.flatten.join(', ')}
    end

    if loan_application
      message = {:notice => "As some crucial information has been updated so the loan application will be considered as new loan application and will again go for dedupe and highmark process."} if is_crucial_info_updated
      redirect resource(@loan_application), :message => message
    else
      display @loan_application, :edit
    end
  end

  def loan_application_list
    @loan_applications = LoanApplication.all(:at_branch_id => params[:at_branch_id], :at_center_id => params[:at_center_id], :status => params[:status])
    render :loan_application_list
  end

  def duplicate_record
    @loan_application  = LoanApplication.get params[:id]
    reference1         = @loan_application.client_reference1
    reference2         = @loan_application.client_reference2
    no_reference1      = reference1.gsub(/[^0-9]/, '')
    no_reference2      = reference2.gsub(/[^0-9]/, '')
    
    @clients           = Client.all(:conditions => ["reference IN ? or reference2 IN ?", [reference1, reference2], [reference1, reference2]])
    @clients           = Client.all(:conditions => ["reference IN ? or reference2 IN ?", [no_reference1, no_reference2], [no_reference1, no_reference2]]) if @clients.blank?
    @clients           = Client.all(:conditions => ["reference LIKE ? or reference LIKE ? or reference2 LIKE ? or reference2 LIKE ?", "%#{no_reference1}%", "%#{no_reference2}%", "%#{no_reference1}%", "%#{no_reference2}%"]) if @clients.blank?
    loan_app_condition = {:conditions => ["client_reference1 IN ? or client_reference2 IN ?",[reference1, reference2], [reference1, reference2]]}
    @loan_applications = LoanApplication.get_all_loan_applications_for_branch_and_center(loan_app_condition) - [@loan_application]
    display @loan_applicaion
  end

  def get_client_age
    begin
      client_dob = Date.parse(params[:client_date_of_birth])
      today_date = Date.today
      age = client_dob.blank? ? 0 : today_date.year - client_dob.year
      return("#{age}")
    rescue => ex
      return("0")
    end
  end

  private

  # method to left trim any digit or value of string
  def trim_lead(string, n)
    trimmed = string.gsub!(/^#{n}+/,'')
    return trimmed.blank? ? string : trimmed
  end
  
  def get_param_value(param_name_sym)
    param_value_str = params[param_name_sym]
    param_value = (param_value_str and (not (param_value_str.empty?))) ? param_value_str : nil
    param_value
  end

  # Fetch suspected loan applicants also fetch cleared or confirmed duplicate loan applicants
  def get_de_dupe_loan_applications
    search_options = {}
    branch_id = params[:parent_location_id]
    center_id = params[:child_location_id]
    @branch = location_facade.get_location(branch_id) if branch_id
    @center = location_facade.get_location(center_id) if center_id
    search_options.merge!(:at_branch_id => @branch.id) unless branch_id.blank?
    search_options.merge!(:at_center_id => @center.id) unless center_id.blank?
    @suspected_duplicates = loan_applications_facade.suspected_duplicate(search_options) unless branch_id.blank?
    @all_loan_applications = loan_applications_facade.get_all_loan_applications_for_branch_and_center(search_options) unless branch_id.blank?
  end

  def fetch_existing_clients_for_new_loan_application(center_id, center_cycle_number)
    center_cycle = loan_applications_facade.get_center_cycle(center_id, center_cycle_number) # TO BE REMOVED ONCE THE REQUIRED REFACTORING IS DONE ON THE MODEL
    client_from_center = client_facade.get_clients_administered(center_id.to_i, Date.today)
    client_ids_from_center = client_from_center.collect{|client| client.id}
    client_ids_from_existing_loan_applications = loan_applications_facade.all_loan_application_client_ids_for_center_cycle(center_id, center_cycle)
    final_client_ids = client_ids_from_center - client_ids_from_existing_loan_applications
    @clients = Client.all(:id => final_client_ids, :order => [:name.asc])
  end

end