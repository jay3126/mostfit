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

  # this lists the clients in the center that has been selected
  def list
    if params[:branch_id] == ""
      @errors = "Please select a branch"  
    elsif params[:center_id] == ""
      @errors = "Please select a center"
    else
      @errors = nil
    end
    @center = Center.get(params[:center_id].to_i)
    if @center
      center_cycle_number = CenterCycle.get_current_center_cycle(@center.id)
      center_cycle = CenterCycle.get_cycle(@center.id, center_cycle_number)
      client_ids_from_center = @center.clients.aggregate(:id) 
      client_ids_from_existing_loan_applications = LoanApplication.all(:at_center_id => @center.id, :center_cycle_id => center_cycle.id).aggregate(:client_id)
      final_client_ids = client_ids_from_center - client_ids_from_existing_loan_applications
      @clients = Client.all(:id => final_client_ids, :order => [:name.asc])
      @loan_applications = LoanApplication.all(:at_center_id => @center.id, :center_cycle_id => center_cycle.id, :order => [:created_at.desc])
    end
    render :bulk_new
  end

  # this function is responsible for creating new loan applications for new loan applicants a.k.a. clients that do not exist in the system 
  def bulk_create
    loan_applications_facade = LoanApplicationsFacade.new(session.user)
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
      @loan_application = loan_applications_facade.create_for_new_applicant(new_application_info, loan_application[:amount], loan_application[:at_branch_id], loan_application[:at_center_id], center_cycle.id, loan_application[:created_by_staff_id], (created_on || Date.today))
      if @loan_application.save
        message[:success] = "The Loan Application has been successfully saved"        
      else
        @errors = @loan_application.errors
      end
    else
      @branch = Branch.get(params["branch_id"])
      @center = Center.get(params["center_id"])      
    end
    @loan_applications = loan_applications_facade.recently_added_applicants({:at_branch_id => @center.branch.id, :at_center_id => @center.id}) if @center
    render
  end

  def suspected_duplicates
    get_de_dupe_loan_applications
    render :suspected_duplicates
  end

  def record_suspected_duplicates
    # GATE-KEEPING
    @errors = {}
    # VALIDATIONS
    if params[:staff_member_id].empty?
      @errors["Suspected duplicates"] = 'Please select staff member'
    end
    if params[:clear_or_confirm_duplicate].nil?
      @errors["Suspected duplicates"] = 'No data passed'
    end
    # POPULATING RESPONSE AND OTHER VARIABLES
    get_de_dupe_loan_applications
    # OPERATIONS PERFORMED
    if @errors.empty?
      params[:clear_or_confirm_duplicate].keys.each do |id|
        lap = LoanApplication.get(id)
        if params[:clear_or_confirm_duplicate][id] == '1'
          result = lap.set_status(Constants::Status::CLEARED_NOT_DUPLICATE_STATUS)
        elsif params[:clear_or_confirm_duplicate][id] == '2'
          result = lap.set_status(Constants::Status::CONFIRMED_DUPLICATE_STATUS)
        end
        @errors["Suspected duplicates"] = "Mandatory details of client is blank.Like pin code, references" if result == false
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
