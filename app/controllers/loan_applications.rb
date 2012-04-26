class LoanApplications < Application
  # provides :xml, :yaml, :js

  def index
    @errors = {}
    @loan_applications = LoanApplicationsFacade.new(session.user).search
    display @loan_applications
  end

  # this controller is responsible for the bulk addition of clients to loan applications
  def bulk_new
    loan_applications_facade = LoanApplicationsFacade.new(session.user)
    @errors = {}
    @center = Center.get(params[:at_center_id].to_i) if params[:at_center_id]
    if request.method == :post
      created_on = Date.parse(params[:created_on])
      center_cycle = CenterCycle.get_cycle(@center.id, params[:center_cycle_number].to_i)
      client_ids = params[:clients].keys
      if params[:staff_member_id].empty? or params[:created_on].empty?
        @errors = []
        @errors << "Please select a Staff Member" if params[:staff_member_id].empty?
        @errors << "Please select a created on date" if params[:created_on].empty?
      else 
        client_ids.each do |client_id|
          client = Client.get(client_id)
          loan_application = loan_applications_facade.create_for_client(client, params[:clients][client_id][:amount].to_i, params[:at_branch_id].to_i, params[:at_center_id].to_i, center_cycle.id, params[:staff_member_id].to_i, created_on) if params[:clients][client_id][:selected] == "on"
          save_status = loan_application.save if loan_application
          @errors[loan_application.client_id] = loan_application.errors if (save_status == false)
        end
      end
      client_ids_from_center = @center.clients.aggregate(:id) if @center
      client_ids_from_existing_loan_applications = LoanApplication.all(:at_center_id => @center.id, :center_cycle_id => center_cycle.id).aggregate(:client_id)
      final_client_ids = client_ids_from_center - client_ids_from_existing_loan_applications
      @clients = Client.all(:id => final_client_ids, :order => [:name.asc])
    end
    @loan_applications = loan_applications_facade.recently_added_applications_for_existing_clients(:at_branch_id => @center.branch.id, :at_center_id => @center.id) if @center
    render
  end

  def get_param_value(param_name_sym)
    param_value_str = params[param_name_sym]
    param_value = (param_value_str and (not (param_value_str.empty?))) ? param_value_str : nil
    param_value
  end

  # this lists the clients in the center that has been selected
  def list
    
    # INITIALIZING VARIABLES USED THROUGHOUT

    @errors = []
    laf = LoanApplicationsFacade.new(session.user)

    # GATEKEEPING

    branch_id = get_param_value(:branch_id)
    center_id = get_param_value(:center_id)

    # VALIDATION

    @errors << "No branch was selected" unless branch_id
    @errors << "No center was selected" unless center_id

    @center = center_id ? Center.get(center_id) : nil
    @errors << "No center was located for center ID: #{center_id}" unless @center

    # OPERATIONS PERFORMED

    if @errors.empty?

      begin
        center_cycle_number = laf.get_current_center_cycle_number(center_id)

        if center_cycle_number > 0
          center_cycle = laf.get_center_cycle(center_id, center_cycle_number) # TO BE REMOVED ONCE THE REQUIRED REFACTORING IS DONE ON THE MODEL
          client_ids_from_center = @center.clients.aggregate(:id)
          client_ids_from_existing_loan_applications = laf.all_loan_application_client_ids_for_center_cycle(center_id, center_cycle)
          final_client_ids = client_ids_from_center - client_ids_from_existing_loan_applications
          @clients = Client.all(:id => final_client_ids, :order => [:name.asc])
        else
          @errors << "No center cycles exist at the center"
        end
      rescue => ex
        @errors << "An error has occurred: #{ex.message}"
      end

    end

    # POPULATING RESPONSE AND OTHER VARIABLES

    if center_id
      @loan_applications = laf.recently_added_applications_for_existing_clients(:at_center_id => center_id)
    end

    # RENDER/RE-DIRECT

    render :bulk_new
  end

  # this function is responsible for creating new loan applications for new loan applicants a.k.a. clients that do not exist in the system 
  def bulk_create
    @errors = {}
    unless params[:flag] == 'true'
      if params[:branch_id].blank?
        @errors['search'] = "No branch selected"
      elsif params[:center_id].blank?
        @errors['search'] = "No center selected"
      end
    end
    if @errors.empty?
      loan_applications_facade = LoanApplicationsFacade.new(session.user)
      @center = Center.get(params["center_id"]) if params["center_id"]
      @branch = Branch.get(params["branch_id"]) if params["branch_id"]
      if request.method == :post
        loan_application = params[:loan_application]
        client_dob = Date.parse(params[:client_dob]) unless params[:client_dob].empty?
        created_on = Date.parse(params[:created_on])
        center_cycle_number = params[:center_cycle_number].to_i
        center_cycle = CenterCycle.get_cycle(@center.id, center_cycle_number)
        new_application_info = {}
        loan_application.keys.each{|x| new_application_info[x.to_sym] = loan_application[x]}
        new_application_info.delete(:amount)
        new_application_info.delete(:at_branch_id)
        new_application_info.delete(:at_center_id)
        new_application_info.delete(:created_by_staff_id)
        new_application_info += {:client_dob => client_dob}
        params.delete(:loan_application)
        @loan_application = loan_applications_facade.create_for_new_applicant(new_application_info, loan_application[:amount], loan_application[:at_branch_id], loan_application[:at_center_id], center_cycle.id, loan_application[:created_by_staff_id], (created_on || Date.today))
        if @loan_application.save
          message[:success] = "The Loan Application has been successfully saved"
        else
          @errors['submit form'] = @loan_application.errors.to_a.flatten.join(', ')
        end
      end
    end

    @loan_applications = loan_applications_facade.recently_added_applicants({:at_branch_id => @center.branch.id, :at_center_id => @center.id}) if @center

    render :bulk_create
  end

  def suspected_duplicates
    get_de_dupe_loan_applications
    render :suspected_duplicates
  end

  def record_suspected_duplicates
    # GATE-KEEPING
    @errors = {}
    staff_member_id = params[:staff_member_id]
    clear_or_confirm_duplicate = params[:clear_or_confirm_duplicate]
    facade = LoanApplicationsFacade.new(session.user)

    # VALIDATIONS
    @errors["Suspected duplicates"] = 'Please select staff member' if staff_member_id.blank?
    @errors["Suspected duplicates"] = 'No data passed' if clear_or_confirm_duplicate.blank?

    # POPULATING RESPONSE AND OTHER VARIABLES
    get_de_dupe_loan_applications

    # OPERATIONS PERFORMED
    if @errors.empty?
      params[:clear_or_confirm_duplicate].keys.each do |lap_id|
        loan_app = LoanApplication.get(lap_id)
        if  params[:clear_or_confirm_duplicate][lap_id].include?('clear')
          is_saved = facade.set_cleared_not_duplicate(lap_id)
        elsif params[:clear_or_confirm_duplicate][lap_id].include?('confirm')
          is_saved = facade.set_confirm_duplicate(lap_id)
        end
        @errors[loan_app.client_id] = loan_app.errors.to_a if is_saved == false
      end
    end
    
    # RENDER/RE-DIRECT
    render :suspected_duplicates
  end

  private

  # Fetch suspected loan applicants also fetch cleared or confirmed duplicate loan applicants
  def get_de_dupe_loan_applications
    facade = LoanApplicationsFacade.new(session.user)
    @suspected_duplicates = facade.suspected_duplicate
    @cleared_or_confirmed_diplicate_loan_files = facade.clear_or_confirm_duplicate
  end

end # LoanApplications
