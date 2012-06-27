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


    # VALIDATIONS

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

    # VALIDATIONS

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

  def distory
  end

  def show
    @client       = Client.get params[:id]
    @client_admin = client_facade.get_administration_on_date(@client, get_effective_date)
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

end
