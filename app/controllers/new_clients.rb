class NewClients < Application

  def index
    effective_date = params[:effective_date]
    unless params[:child_location_id].blank?
      @biz_location    = BizLocation.get params[:child_location_id]
      @parent_location = BizLocation.get params[:parent_location_id]
      @child_locations = location_facade.get_children(@parent_location, effective_date) - [@biz_location]
      @clients         = client_facade.get_clients_administered(@biz_location.id, effective_date)
      @clients         = @clients.select{|client| client.move_client?}
      @client_admins   = @clients.collect{|client| ClientAdministration.get_current_administration(client)}
    end
    display @client_admins
  end

  def new
    @biz_location = BizLocation.get params[:biz_location_id]
    @client       = Client.new
    if @biz_location.blank?
      redirect url(:home), :message => {:error => "Please select location"}
    else
      display @client
    end
  end

  def create
    # INITIALIZATION VARIABLES USED THROUGHTOUT

    @message = {}
    # GATE KEEPING
    created_by              = session.user.id
    client_type             = params[:client_type]
    biz_location_id         = params[:biz_location]
    created_by_staff        = params[:client][:created_by_staff]
    client_group_id         = params[:client][:client_group_id]
    name                    = params[:client][:name]
    gender                  = params[:client][:gender]
    marital_status          = params[:client][:marital_status]
    reference_type          = params[:client][:reference_type]
    reference               = params[:client][:reference]
    reference2_type         = params[:client][:reference2_type]
    reference2              = params[:client][:reference2]
    date_of_birth           = params[:client][:date_of_birth]
    date_joined             = params[:client][:date_joined]
    spouse_name             = params[:client][:spouse_name]
    spouse_date_of_birth    = params[:client][:spouse_date_of_birth]
    guarantor_name          = params[:client][:guarantor_name]
    guarantor_dob           = params[:client][:guarantor_dob]
    guarantor_relationship  = params[:client][:guarantor_relationship]
    address                 = params[:client][:address]
    state                   = params[:client][:state]
    pincode                 = params[:client][:pincode]
    telephone_number        = params[:client][:telephone_number]
    telephone_type          = params[:client][:telephone_type]
    income                  = params[:client][:income]
    family_income           = params[:client][:family_income]
    occupation_id           = params[:client][:occupation_id]
    priority_sector_list_id = params[:client][:priority_sector_list_id]
    psl_sub_category_id     = params[:client][:psl_sub_category_id]
    caste                   = params[:client][:caste]
    religion                = params[:client][:religion]
    picture                 = params[:client][:picture]
    classification          = params[:client][:town_classification]

    # remove leading and trailing spaces from reference-1 and reference-2
    reference = reference.strip unless reference.blank?
    reference2 = reference2.strip unless reference2.blank?

    # VALIDATIONS
    @message[:error] = "Date joined must not be future date" if date_joined && Date.parse(date_joined) > Date.today

    # OPERATIONS PERFORMED
    fields = {:client_group_id => client_group_id,:name => name, :gender => gender, :marital_status => marital_status, :reference_type => reference_type,
      :reference => reference, :reference2_type => reference2_type, :reference2 => reference2, :date_of_birth => date_of_birth, :date_joined => date_joined,
      :spouse_name => spouse_name, :spouse_date_of_birth => spouse_date_of_birth, :guarantor_name => guarantor_name, :guarantor_dob => guarantor_dob,
      :guarantor_relationship => guarantor_relationship, :address => address, :state => state, :pincode => pincode, :telephone_number => telephone_number,
      :telephone_type => telephone_type, :income => income, :family_income => family_income, :priority_sector_list_id => priority_sector_list_id,
      :psl_sub_category_id => psl_sub_category_id, :caste => caste, :religion => religion, :picture => picture, :created_by_staff_member_id => created_by_staff, :town_classification => classification,
      :created_by_user_id => created_by}
    @client = Client.new(fields)

    if @message[:error].blank?
      begin
        @biz_location = BizLocation.get biz_location_id
        parent_biz_location = LocationLink.get_parent(@biz_location, get_effective_date)


        @client_new = Client.create_client(fields, biz_location_id, parent_biz_location.id)

        if @client_new.new?
          @message = {:error => "Client creation failed"}
        else
          @message = {:notice => "Client: '#{@client_new.name} (Id: #{@client_new.id})' created successfully"}
        
        end
      rescue => ex
        @message = {:error => "An error has occured: #{ex.message}"}
      end
    end
    # REDIRECT/RENDER
    if @message[:error].blank?
      redirect url(:controller => :new_clients, :action => :show, :id => @client_new.id), :message => @message
    else
      render :new
    end
  end

  def edit
    @client = Client.get params[:id]
    display @client
  end

  def update
    # INITIALIZATION VARIABLES USED THROUGHTOUT

    @message = {}
    
    # GATE KEEPING
    created_by              = session.user.id
    client_id               = params[:id]
    client_type             = params[:client_type]
    created_by_staff        = params[:client][:created_by_staff]
    client_group_id         = params[:client][:client_group_id]
    name                    = params[:client][:name]
    gender                  = params[:client][:gender]
    marital_status          = params[:client][:marital_status]
    reference_type          = params[:client][:reference_type]
    reference               = params[:client][:reference]
    reference2_type         = params[:client][:reference2_type]
    reference2              = params[:client][:reference2]
    date_of_birth           = params[:client][:date_of_birth]
    date_joined             = params[:client][:date_joined]
    spouse_name             = params[:client][:spouse_name]
    spouse_date_of_birth    = params[:client][:spouse_date_of_birth]
    guarantor_name          = params[:client][:guarantor_name]
    guarantor_dob           = params[:client][:guarantor_dob]
    guarantor_relationship  = params[:client][:guarantor_relationship]
    address                 = params[:client][:address]
    state                   = params[:client][:state]
    pincode                 = params[:client][:pincode]
    telephone_number        = params[:client][:telephone_number]
    telephone_type          = params[:client][:telephone_type]
    income                  = params[:client][:income]
    family_income           = params[:client][:family_income]
    occupation_id           = params[:client][:occupation_id]
    priority_sector_list_id = params[:client][:priority_sector_list_id]
    psl_sub_category_id     = params[:client][:psl_sub_category_id]
    caste                   = params[:client][:caste]
    religion                = params[:client][:religion]
    picture                 = params[:client][:picture]
    classification          = params[:client][:town_classification]

    # remove leading and trailing spaces from reference-1 and reference-2
    reference = reference.strip unless reference.blank?
    reference2 = reference2.strip unless reference2.blank?

    # VALIDATIONS
    @message[:error] = "Date joined must not be future date" if date_joined && Date.parse(date_joined) > Date.today

    # OPERATIONS PERFORMED
    @client = Client.get client_id
    @client.attributes = {:client_group_id => client_group_id,:name => name, :gender => gender, :marital_status => marital_status, :reference_type => reference_type,
      :reference => reference, :reference2_type => reference2_type, :reference2 => reference2, :date_of_birth => date_of_birth, :date_joined => date_joined,
      :spouse_name => spouse_name, :spouse_date_of_birth => spouse_date_of_birth, :guarantor_name => guarantor_name, :guarantor_dob => guarantor_dob,
      :guarantor_relationship => guarantor_relationship, :address => address, :state => state, :pincode => pincode, :telephone_number => telephone_number,
      :telephone_type => telephone_type, :income => income, :family_income => family_income, :priority_sector_list_id => priority_sector_list_id,
      :psl_sub_category_id => psl_sub_category_id, :caste => caste, :religion => religion, :picture => picture, :created_by_staff_member_id => created_by_staff, :town_classification => classification,
      :created_by_user_id => created_by}
    if @message[:error].blank?
      begin
        if @client.save
          @message = {:notice => "Client: '#{@client.name} (#{@client.id})' updated successfully"}
        else
          @message = { :error => @client.errors.collect{|error| error}.flatten.join(', ')}
        end
      rescue => ex
        @message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    # REDIRECT/RENDER
    if @message[:error].blank?
      redirect url(:controller => :new_clients, :action => :show, :id => @client.id), :message => @message
    else
      render :edit
    end
  end

  def show
    @client       = Client.get params[:id]
    date_joined   = @client.date_joined
    client_administration_on_date = get_effective_date ? [get_effective_date, date_joined].max : date_joined
    @client_admin = client_facade.get_administration_on_date(@client, client_administration_on_date)
    @biz_location = @client_admin.administered_at_location
    @lendings     = LoanBorrower.get_all_loans_for_counterparty(@client).compact
    #generate cc route
    request = Merb::Request.new(Merb::Const::REQUEST_PATH => url(:cc_checklist),Merb::Const::REQUEST_METHOD => "GET")
    @cc_route = Merb::Router.match(request)[1] rescue nil
    display @client
  end

  def show_accounts
    @ledgers       = []
    @client        = Client.get params[:id]
    @lendings      = LoanBorrower.get_all_loans_for_counterparty(@client)
    @account_chart = AccountsChart.setup_counterparty_accounts_chart(@client)

    if @lendings.blank?
      ledger_map = Ledger.setup_product_ledgers(@account_chart, :INR, @client.date_joined)
      @ledgers   = ledger_map.values
    else
      @lendings.each do |lending|
        ledger_map = Ledger.setup_product_ledgers(@account_chart, :INR, @client.date_joined, :lending, lending.id)
        @ledgers << ledger_map.values
      end
    end
    @ledgers = @ledgers.flatten.uniq.group_by{|l| l.account_type}
    partial "new_clients/show_accounts"
  end

  def update_client_location
    @message        = {:error => [], :notice => []}
    assign_clients  = []
    client_params   = params[:client]
    parent_location = params[:parent_biz_location]
    child_location  = params[:child_biz_location]
    client_ids      = client_params[:move_client_ids]
    effective_date  = params[:effective_date]
    move_date       = params[:move_on_date]
    by_staff        = client_params[:move_by_staff]
    recorded_by     = session.user.id
    move_on_location = client_params[:biz_location_id]
    @message[:error] << "Please select client for assignment" if client_ids.blank?
    @message[:error] << "Please select Performed By" if by_staff.blank?
    @message[:error] << "Date cannot be blank" if move_date.blank?
    @message[:error] << "Please select Center" if move_on_location.blank?

    begin
      if @message[:error].blank?
        client_ids.each do |client_id|
          assignment = {}
          assignment[:administered_at]   = move_on_location
          assignment[:registered_at]     = parent_location
          assignment[:counterparty_type] = :client
          assignment[:counterparty_id]   = client_id
          assignment[:effective_on]      = move_date
          assignment[:performed_by]      = by_staff
          assignment[:recorded_by]       = recorded_by
          client_assign                  = ClientAdministration.new(assignment)
          if client_assign.valid?
            assign_clients << client_assign
          else
            @message[:error] << client_assign.errors.first.join("dd").map{|d| "Client #{client_id} :- #{d}"}.join("<br>")
          end
        end
        if @message[:error].blank?
          assign_clients.each{|assign_client| assign_client.save}
          @message[:notice] = "Client assignment successfully"
        end
      end
    rescue => ex
      @message = {:error => "An error has occured: #{ex.message}"}
    end

    @message[:error].blank? ? @message.delete(:error) : @message.delete(:notice)
    redirect url(:controller => :new_clients, :action => :index, :child_location_id => child_location, :parent_location_id => parent_location, :effective_date => effective_date) , :message => @message
  end

  def update_client_telephone_number
    error = ''
    client = Client.get(params[:id])
    client.telephone_number = params[:phone_number]
    default_text = "<div style='margin-top: 0pt; float: right;', onclick="+"jQuery('div.flash').remove();"+"><a class='closeNotice' href='#'>[X]</a></div>"
    error = "Client Phone Number is not valid format" if params[:phone_number].to_i <= 0 || params[:phone_number].size > 14 || params[:phone_number] != params[:phone_number].to_i.to_s
    if error.blank?
      if client.save
        message = "<div class='flash notice'><b>#{default_text}Client Phone Number Updated<b></div>"
      else
        message = "<div class='flash error'>#{default_text}#{client.errors.first.join('<br>')}</div>"
      end
    else
      message = "<div class='flash error'>#{error}</div>"
    end
    message
  end

  def client_movement
    @client = Client.get params[:id]
    @client_admins = ClientAdministration.get_counterparty_administration(@client)
    partial 'new_clients/client_movement'
  end

  #this function is used by the router for proper redirection.
  def redirect_to_show(id)
    redirect url(:controller => :new_clients, :action => :show, :id => id)
  end

  def create_clients_for_loan_file
    loan_file_id = params[:loan_file_id]
    raise NotFound, "Loan file not found" if loan_file_id.blank?
    @loan_file = LoanFile.get loan_file_id
    branch_id = @loan_file.at_branch_id
    @branch = BizLocation.get branch_id
    center_id = @loan_file.at_center_id
    @center = BizLocation.get center_id
    @center_cycle_number = CenterCycle.get_current_center_cycle(center_id)

    display @loan_file
  end

  def create_client_for_selected_loan_application
    # INITIALIZATION
    @errors = []

    # GATE-KEEPING
    loan_file_id = params[:loan_file_id]
    loan_application_ids = params[:selected].keys

    # VALIDATIONS
    @errors << "Select atleast one loan application" if loan_application_ids.blank?

    # OPERATION PERFORMED
    if @errors.blank?
      loan_application_ids.each do |loan_application_id|
        begin
          loan_application = LoanApplication.get loan_application_id
          loan_application.create_client
          loan_application.set_status(Constants::Status::CLIENT_CREATED)
          message = {:notice => "Successfully created client for Loan Application ID #{loan_application_id} as Client ID #{loan_application.client_id}"}
        rescue => ex
          @errors << "An error has occured for Loan Application ID #{loan_application_id}: #{ex.message}"
        end
      end

    end

    unless @errors.blank?
      message = {:error => @errors.flatten.join(', ')}
    end

    # RE-DIRECT
    redirect url("new_clients/create_clients_for_loan_file?loan_file_id=#{loan_file_id}"), :message => message
  end

  def register_death_event
    client_id = params[:id]
    @client = Client.get client_id
    display @client
  end

  def record_death_event
    # INITIALIZATION
    @errors = []

    # GATE-KEEPING
    client_id = params[:client_id]
    @client = Client.get client_id
    deceased_name = params[:deceased_name]
    relationship_to_client = params[:relationship_to_client]
    date_of_death_str = params[:date_of_death]
    date_of_death = Date.parse(date_of_death_str) unless date_of_death_str.blank?
    reported_on_str = params[:reported_on]
    reported_on = Date.parse(reported_on_str) unless reported_on_str.blank?
    recorded_by = session.user.id
    reported_by = params[:reported_by]

    # VALIDATIONS
    @errors << "Deceased name must not be blank" if deceased_name.blank?
    @errors << "Relationship to client must not be blank" if relationship_to_client.blank?
    @errors << "Date of death must not be future date" if date_of_death > Date.today
    @errors << "Reported on date must not be future date" if reported_on > Date.today
    @errors << "Reported on date must not before Date of death" if reported_on < date_of_death
    @errors << "Reported by must not be blank" if reported_by.blank?

    # OPERATIONS PERFORMED
    if @errors.blank?
      begin
        is_saved = DeathEvent.save_death_event(deceased_name, relationship_to_client, date_of_death_str, reported_on_str, reported_on, recorded_by, reported_by, client_id)
        message = {:notice => "Death event successfully registered"} if is_saved
      rescue => ex
        @errors << "An error has occured: #{ex.message}"
      end
      redirect url("new_clients/show/#{client_id}"), :message => message
    else
      render :register_death_event
    end
  end

  def client_insurance_policies
    @client = Client.get params[:id]
    @policies = @client.simple_insurance_policies
    render :template => 'simple_insurance_policies/index', :layout => layout?
  end

  def death_claims
    client_id = params[:client_id]
    @client = Client.get client_id
    partial "death_claims"
  end

  def death_claim_insurance
    @simple_insurance_policy = params[:simple_insurance_policy]
    death_event_id           = params[:death_event_id]
    @death_event             = DeathEvent.get death_event_id
    client_id                = @death_event.affected_client_id
    date_for_accounted_at    = @death_event.date_of_death
    @client                  = Client.get client_id
    @accounted_at            = ClientAdministration.get_registered_at(@client, date_for_accounted_at).id
    render
  end

  def record_death_claim_insurance
    # INITIALIZATION
    @errors = []
    
    # GATE-KEEPING
    claim_status = params[:claim_status]
    death_event_id = params[:death_event_id]
    accounted_at_id = params[:accounted_at_id]
    filed_on_date_str = params[:filed_on]
    performed_by_id = params[:performed_by]
    recorded_by_id = session.user.id
    client_id = params[:client_id]
    on_insurance_policy_id = params[:simple_insurance_policy]
    filed_on_date = Date.parse(filed_on_date_str) unless filed_on_date_str.blank?
    death_event = DeathEvent.get death_event_id
    on_insurance_policy = SimpleInsurancePolicy.get on_insurance_policy_id

    # VALIDATIONS
    @errors << "Claim status must not be blank" if claim_status.blank?
    @errors << "Performed by must not be blank" if performed_by_id.blank?
    @errors << "Claim filed on date must not be future date" if filed_on_date > Date.today

    # OPERATIONS PERFORMED
    if @errors.blank?
      begin
        InsuranceClaim.file_insurance_claim_for_death_event(death_event, claim_status, on_insurance_policy, filed_on_date_str, accounted_at_id, performed_by_id, recorded_by_id)
        message = {:notice => "Successfully saved insuranc claim"}
      rescue => ex
        message = {:error => "An error has occured: #{ex.message}"}
      end
      redirect url("new_clients/show/#{client_id}"), :message => message
    else
      render :death_claim_insurance
    end
  end

  def all_deceased_clients
    @deceased_clients = client_facade.get_all_deceased_clients
    render
  end

  def mark_claim_documents_recieved
    # GATE-KEEPING
    selected_clients = params[:clients]
    recieved_by = get_session_user_id
    recieved_on = params[:document_recieved_on]

    # INITIALIZATIONS
    @errors = []
    message = {}
    # VALIDATIONS
    @errors << "Select atleast one client" if selected_clients.blank?
    @errors << "Select date document submission" if recieved_on.blank?
    
    # OPERATIONS PERFORMED
    if @errors.blank?
      client_ids = selected_clients.keys
      client_ids.each do |client_id|
        begin
          client = Client.get client_id
          claim_document_recieved_on = params[:document_recieved_on]["#{client_id}"]
          is_client_died = client_facade.death_event_filed_for(client) == "Client"
          all_loans = client_facade.get_all_loans_for_counterparty(client).compact
          all_loans.each do |loan|
            loan.set_status(LoanLifeCycle::REJECTED_LOAN_STATUS, Date.today)
          end
          client_facade.mark_client_as_inactive(client) if is_client_died
          client_facade.mark_client_documents_recieved(client, recieved_by, claim_document_recieved_on)
          message = {:notice => "Documents successfully submitted for Client: #{client} and Due generation as been stopped for all loans."}
        rescue => ex
          @errors << "An error has occured #{ex.message}"
          message = {:error => @errors.flatten.join(', ')}
        end
      end
    else
      message = {:error => @errors.flatten.join(', ')}
    end
    redirect resource(:new_clients, :all_deceased_clients), :message => message
  end

  def bulk_update_client_details
    # GATE-KEEPING
    client_ids = params[:client_ids].keys
    # INITIALIZATIONS
    @errors = []
    message = {}
    c_ids = []

    # OPERATIONS-PERFORMED
    if @errors.blank?
      client_ids.each do |client_id|
        begin
          client_hash = {}
          client_hash[:marital_status] = params[:marital_status][client_id]
          client_hash[:caste] = params[:caste][client_id]
          client_hash[:income] = params[:income][client_id]
          client_hash[:spouse_date_of_birth] = params[:spouse_date_of_birth][client_id]
          client_hash[:gender] = params[:gender][client_id]
          client_hash[:family_income] = params[:family_income][client_id]
          client_hash[:telephone_type] = params[:telephone_type][client_id]
          client_hash[:religion] = params[:religion][client_id]
          client_hash[:occupation_id] = params[:occupation_id][client_id] rescue ""
          client_hash[:psl_sub_category_id] = params[:psl_sub_category_id][client_id] rescue ""
          client_hash[:spouse_name] = params[:spouse_name][client_id]
          client_hash[:guarantor_dob] = params[:guarantor_dob][client_id]
          client_hash[:priority_sector_list_id] = params[:priority_sector_list_id][client_id] rescue ""
          client_hash[:telephone_number] = params[:telephone_number][client_id]
          client = Client.get client_id
          client.update_client_details_in_bulk(client_hash)
          c_ids << client_id
          message = {:notice => "Successfully updated Client ID: #{c_ids.flatten.join(', ')}."}
        rescue => ex
          @errors << "An error has occured for Client ID #{client_id}: #{ex.message}"
          message = {:error => @errors.flatten.join(', ')}
        end
      end
    end
    
    # REDIRECT
    redirect url("new_clients/create_clients_for_loan_file?loan_file_id=#{params[:loan_file_id]}"), :message => message
  end

  def client_attendance
    @client = Client.get params[:id]
    @attendances = @client.attendance_records
    partial 'new_clients/client_attendances'
  end

end