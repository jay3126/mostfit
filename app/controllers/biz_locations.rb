class BizLocations < Application

  def index
    @location_levels = LocationLevel.all
    @biz_locations   = BizLocation.all.group_by{|c| c.location_level.level}
    @biz_location    = BizLocation.new()
    display @location_levels
  end

  def edit
    @biz_location = BizLocation.get params[:id]
    display @biz_location
  end

  def update_biz_location
    # INITIALIZING VARIABLES USED THROUGHTOUT

    message = {}

    # GATE-KEEPING

    b_name           = params[:biz_location][:name]
    b_disbursal_date = params[:biz_location][:center_disbursal_date]
    b_address        = params[:biz_location][:biz_location_address]
    b_id             = params[:id]

    # VALIDATIONS

    message[:error] = "Name cannot be blank" if b_name.blank?
    message[:error] = "Biz Location cannot be blank" if b_id.blank?
    @biz_location   = BizLocation.get b_id

    # OPERATIONS PERFORMED
    if message[:error].blank?
      begin
        @biz_location.attributes = {:name => b_name, :center_disbursal_date => b_disbursal_date, :biz_location_address => b_address}
        if @biz_location.save
          message = {:notice => " Location successfully Updated"}
        else
          message = {:error => @biz_location.errors.first.join(', ')}
        end
      rescue => ex
        message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    #REDIRECT/RENDER
    if message[:error].blank?
      if @biz_location.location_level.level == 0
        redirect url(:controller => :user_locations, :action => :weeksheet_collection, :id => @biz_location.id), :message => message
      else
        redirect url(:user_location, :action => :show, :id => @biz_location.id), :message => message
      end
    else
      redirect resource(@biz_location, :edit), :message => message
    end
  end

  def create
    # INITIALIZING VARIABLES USED THROUGHTOUT

    message = {}

    # GATE-KEEPING

    b_level            = params[:biz_location][:location_level]
    b_creation_date    = params[:biz_location][:creation_date]
    b_name             = params[:biz_location][:name]
    b_address          = params[:biz_location][:biz_location_address]
    b_disbursal_date   = params[:biz_location][:center_disbursal_date]
    parent_location_id = params[:parent_location_id]

    # VALIDATIONS

    message[:error] = "Name cannot be blank" if b_name.blank?
    message[:error] = "Please select Location Level" if b_level.blank?
    message[:error] = "Creation Date cannot blank" if b_creation_date.blank?
    parent_location = BizLocation.get(parent_location_id) unless parent_location_id.blank?

    # OPERATIONS PERFORMED
    if message[:error].blank?
      begin
        biz_location = location_facade.create_new_location(b_name, b_creation_date, b_level.to_i, b_address, b_disbursal_date)
        if biz_location.new?
          message = {:notice => "Location creation fail"}
        else
          LocationLink.assign(biz_location, parent_location, b_creation_date) unless parent_location.blank?
          message = {:notice => " Location successfully created"}
        end
      rescue => ex
        message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    #REDIRECT/RENDER
    redirect resource(:biz_locations), :message => message
  
  end

  def show
    @biz_location     = BizLocation.get params[:id]
    @biz_locations    = LocationLink.all(:parent_id => @biz_location.id).group_by{|c| c.child.location_level.level}
    location_level    = LocationLevel.first(:level => (@biz_location.location_level.level - 1))
    @parent_locations = BizLocation.all_locations_at_level(@biz_location.location_level.level)
    @child_locations  = location_level.blank? ? [] : BizLocation.all_locations_at_level(location_level.level)
    display @biz_location
  end

  def map_locations
    # INITIALIZING VARIABLES USED THROUGHTOUT

    message = {}
    parent  = ''
    child   = ''

    # GATE-KEEPING

    p_location    = params[:parent_location]
    c_location    = params[:child_location]
    creation_date = Date.parse(params[:begin_date])

    # VALIDATIONS

    message[:error] = "Please select Parent Location" if p_location.blank?
    message[:error] = "Please select Child Location" if c_location.blank?
    message[:error] = "Creation Date cannot blank" if creation_date.blank?

    # OPERATIONS PERFORMED
    if message[:error].blank?
      begin
        parent = BizLocation.get p_location
        child  = BizLocation.get c_location
        if location_facade.assign(child, parent, creation_date)
          message = {:notice => " Location Mapping successfully created"}
        else
          message = {:error => "Save Location Mapping fail"}
        end
      rescue => ex
        message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    #REDIRECT/RENDER
    if parent.blank?
      redirect request.referer, :message => message
    else
      redirect resource(parent), :message => message
    end
  end

  def biz_location_clients
    @biz_location = BizLocation.get params[:id]
    @clients      = client_facade.get_clients_administered(@biz_location.id, get_effective_date)
    display @clients
  end

  def centers_for_selector
    if params[:id]
      location_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, session.user)
      branch = location_facade.get_location(params[:id])
      effective_date = params[:effective_date]
      centers = location_facade.get_children(branch, effective_date)
      return("<option value=''>Select center</option>"+centers.map{|center| "<option value=#{center.id}>#{center.name}"}.join)
    else
      return("<option value=''>Select center</option>")
    end
  end

  def locations_for_location_level
    if params[:location_level].blank?
      return("<option value=''>Select Location</option>")
    else
      location_level = LocationLevel.first(:level => params[:location_level].to_i+1)
      locations      = location_level.biz_locations rescue []
      return("<option value=''>Select Location</option>"+locations.map{|location| "<option value=#{location.id}>#{location.name}"}.join)
    end
  end
  
  def biz_location_form
    @biz_location = BizLocation.get params[:id]
    level = @biz_location.location_level.level
    @child_location_level = LocationLevel.first(:level => level-1)
    render :partial => 'biz_locations/location_fields', :layout => layout?
  end

  def create_and_assign_location
    # INITIALIZING VARIABLES USED THROUGHTOUT

    message = {}

    # GATE-KEEPING

    b_level          = params[:location_level]
    b_creation_date  = params[:creation_date]
    b_name           = params[:name]
    b_id             = params[:id]
    @parent_location = BizLocation.get b_id

    # VALIDATIONS

    message[:error] = "Name cannot be blank" if b_name.blank?
    message[:error] = "Please select Location Level" if b_level.blank?
    message[:error] = "Creation Date cannot blank" if b_creation_date.blank?
    message[:error] = "Parent location is invaild" if @parent_location.blank?
    
    # OPERATIONS PERFORMED
    if message[:error].blank?
      begin
        child_location = location_facade.create_new_location(b_name, b_creation_date, b_level.to_i)
        if child_location.new?
          message = {:notice => "Location creation fail"}
        else
          location_facade.assign(child_location, @parent_location, b_creation_date)
          message = {:notice => " Location successfully created"}
        end
      rescue => ex
        message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    #REDIRECT/RENDER
    redirect url(:controller => :user_locations, :action => :show, :id => @parent_location.id), :message => message

  end

  def update
  end

  def destroy
  end

end 
