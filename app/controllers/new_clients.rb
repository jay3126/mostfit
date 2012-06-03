class NewClients < Application

  def index
  end

  def new
    @biz_location = BizLocation.get params[:biz_location]
    @client = Client.new
    display @client
  end

  def create
    # INITIALIZATION VARIABLES USED THROUGHTOUT

    @message = {}
    # GATE KEEPING
    created_by              = session.user.id
    client_type             = params[:client_type]
    biz_location_id         = params[:biz_location]
    created_by_staff        = params[:client][:created_by_staff]
    group_id                = params[:client][:client_group_id]
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
      @client = Client.new(:name => name, :gender => gender, :marital_status => marital_status, :reference_type => reference_type,
        :reference => reference, :reference2_type => reference2_type, :reference2 => reference2, :date_of_birth => date_of_birth, :date_joined => date_joined,
        :spouse_name => spouse_name, :spouse_date_of_birth => spouse_date_of_birth, :guarantor_name => guarantor_name, :guarantor_dob => guarantor_dob,
        :guarantor_relationship => guarantor_relationship, :address => address, :state => state, :pincode => pincode, :telephone_number => telephone_number,
        :telephone_type => telephone_type, :income => income, :family_income => family_income, :priority_sector_list_id => priority_sector_list_id,
        :psl_sub_category_id => psl_sub_category_id, :caste => caste, :religion => religion, :picture => picture, :created_by_staff_member_id => created_by_staff,
        :created_by_user_id => created_by)
      if @client.save
        parent_biz_location = LocationLink.get_parent(@biz_location, Date.today)
        ClientAdministration.assign(@biz_location, parent_biz_location , @client, created_by_staff, created_by, date_joined)
        @message = {:notice => "Client created successfully"}
      else
        @message = { :error => @client.errors.collect{|error| error}.flatten.join(', ')}
      end
    rescue => ex
      @message = {:error => "An error has occured: #{ex.message}"}
    end

    # REDIRECT/RENDER
    if @message[:error].blank?
      redirect resource(@biz_location, :biz_location_clients), :message => @message
    else
      render :new
    end

  end

  def edit
  end

  def update
  end

  def distory
  end
end