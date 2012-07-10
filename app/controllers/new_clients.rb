class NewClients < Application

  def index
    effective_date = params[:effective_date]
    unless params[:child_location_id].blank?
      @biz_location    = BizLocation.get params[:child_location_id]
      @parent_location = BizLocation.get params[:parent_location_id]
      @child_locations = location_facade.get_children(@parent_location, effective_date) - [@biz_location]
      @clients         = client_facade.get_clients_administered(@biz_location.id, effective_date)
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

    # remove leading and trailing spaces from reference-1 and reference-2
    reference = reference.strip unless reference.blank?
    reference2 = reference2.strip unless reference2.blank?

    # OPERATIONS PERFORMED
    begin
      @biz_location = BizLocation.get biz_location_id
      parent_biz_location = LocationLink.get_parent(@biz_location, get_effective_date)
      fields = {:client_group_id => client_group_id,:name => name, :gender => gender, :marital_status => marital_status, :reference_type => reference_type,
        :reference => reference, :reference2_type => reference2_type, :reference2 => reference2, :date_of_birth => date_of_birth, :date_joined => date_joined,
        :spouse_name => spouse_name, :spouse_date_of_birth => spouse_date_of_birth, :guarantor_name => guarantor_name, :guarantor_dob => guarantor_dob,
        :guarantor_relationship => guarantor_relationship, :address => address, :state => state, :pincode => pincode, :telephone_number => telephone_number,
        :telephone_type => telephone_type, :income => income, :family_income => family_income, :priority_sector_list_id => priority_sector_list_id,
        :psl_sub_category_id => psl_sub_category_id, :caste => caste, :religion => religion, :picture => picture, :created_by_staff_member_id => created_by_staff,
        :created_by_user_id => created_by}

      @client     = Client.new(fields)
      @client_new = Client.create_client(fields, biz_location_id, parent_biz_location.id)

      if @client_new.new?
        @message = {:error => "Client creation fail"}
      else
        @message = {:notice => "Client created successfully"}
        
      end
    rescue => ex
      @message = {:error => "An error has occured: #{ex.message}"}
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

    # remove leading and trailing spaces from reference-1 and reference-2
    reference = reference.strip unless reference.blank?
    reference2 = reference2.strip unless reference2.blank?

    # OPERATIONS PERFORMED
    begin
      @client = Client.get client_id
      @client.attributes = {:client_group_id => client_group_id,:name => name, :gender => gender, :marital_status => marital_status, :reference_type => reference_type,
        :reference => reference, :reference2_type => reference2_type, :reference2 => reference2, :date_of_birth => date_of_birth, :date_joined => date_joined,
        :spouse_name => spouse_name, :spouse_date_of_birth => spouse_date_of_birth, :guarantor_name => guarantor_name, :guarantor_dob => guarantor_dob,
        :guarantor_relationship => guarantor_relationship, :address => address, :state => state, :pincode => pincode, :telephone_number => telephone_number,
        :telephone_type => telephone_type, :income => income, :family_income => family_income, :priority_sector_list_id => priority_sector_list_id,
        :psl_sub_category_id => psl_sub_category_id, :caste => caste, :religion => religion, :picture => picture, :created_by_staff_member_id => created_by_staff,
        :created_by_user_id => created_by}
      if @client.save
        @message = {:notice => "Client updated successfully"}
      else
        @message = { :error => @client.errors.collect{|error| error}.flatten.join(', ')}
      end
    rescue => ex
      @message = {:error => "An error has occured: #{ex.message}"}
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
    @message        = {}
    parent_location = params[:parent_biz_location]
    child_location  = params[:child_biz_location]
    client_id       = params[:client_id]
    effective_date  = params[:effective_date]
    client_params   = params[:client][client_id].blank? ? [] : params[:client][client_id].first
    @message        = {:error => "Please select client for assignment"} if client_params.blank?

    begin
      if @message[:error].blank?
        administered_location = BizLocation.get client_params[:biz_location]
        registered_location   = BizLocation.get parent_location
        client                = Client.get client_id
        performed_by          = client_params[:performed_by]
        effective_on          = client_params[:effective_on]
        recorded_by           = session.user.id
        client                = ClientAdministration.assign(administered_location, registered_location, client, performed_by, recorded_by, effective_on)
        if client.new?
          @message = {:error => "Client assignment fails."}
        else
          @message = {:notice => "Client assignment successfully."}
        end
      end
    rescue => ex
      @message = {:error => "An error has occured: #{ex.message}"}
    end
    
    if @message[:error].blank?
      redirect url(:controller => :new_clients, :action => :show, :id => client_id) , :message => @message
    else
      redirect url(:controller => :new_clients, :action => :index, :child_location_id => child_location, :parent_location_id => parent_location, :effective_date => effective_date) , :message => @message
    end
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
    loan_application_id = params[:loan_application_id]

    # OPERATION PERFORMED
    begin
      loan_application = LoanApplication.get loan_application_id
      loan_application.create_client
      message = {:notice => "Successfully created client for Loan Application ID #{loan_application_id} as Client ID #{loan_application.client_id}"}
    rescue => ex
      @errors << "An error has occured for Loan Application ID #{loan_application_id}: #{ex.message}"
    end
    unless @errors.blank?
      message = {:error => @errors.flatten.join(', ')}
    end

    # RE-DIRECT
    redirect url("new_clients/create_clients_for_loan_file?loan_file_id=#{loan_file_id}"), :message => message
  end

  def register_death_event
    client_id = params[:client_id]
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
    death_event_id = params[:death_event_id]
    @death_event = DeathEvent.get death_event_id
    client_id = @death_event.affected_client_id
    date_for_accounted_at = @death_event.date_of_death
    @client = Client.get client_id
    @accounted_at = ClientAdministration.get_registered_at(@client, date_for_accounted_at).id
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
    filed_on_date = Date.parse(filed_on_date_str) unless filed_on_date_str.blank?

    # VALIDATIONS
    @errors << "Claim status must not be blank" if claim_status.blank?
    @errors << "Performed by must not be blank" if performed_by_id.blank?
    @errors << "Claim filed on date must not be future date" if filed_on_date > Date.today
    
    # OPERATIONS PERFORMED
    if @errors.blank?
      begin
      InsuranceClaim.file_insurance_claim_for_death_event(death_event_id, claim_status, on_insurance_policy, filed_on_date_str, accounted_at_id, performed_by_id, recorded_by_id)
      message = {:notice => "Successfully saved insurance"}
      rescue => ex
        message = {:error => "An error has occured: #{ex.message}"}
      end
      redirect url("new_clients/show/#{client_id}"), :message => message
    else
     render :death_claim_insurance
    end
  end

end