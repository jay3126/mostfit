class BizLocations < Application

  def index
    if params[:location_level_id].blank?
      @location_level = ''
      @biz_locations = []
    else
      @location_level = LocationLevel.get(params[:location_level_id])
      @biz_locations = @location_level.biz_locations
    end
    display @biz_locations
  end

  def edit
    @biz_location     = BizLocation.get params[:id]
    @parent_location  = LocationLink.get_parent(@biz_location, get_effective_date)
    location_id       = @biz_location.location_level.level == 0 ? @parent_location.id : @biz_location.id
    @staff_members    = StaffPosting.get_staff_assigned(location_id, get_effective_date).map(&:staff_assigned) rescue []
    @managed_by_staff = location_facade.location_managed_by_staff(@biz_location.id, get_effective_date).manager_staff_member rescue ''
    display @biz_location
  end

  def update_biz_location
    # INITIALIZING VARIABLES USED THROUGHTOUT

    message = {:error => [], :notice => []}
    # GATE-KEEPING

    b_name           = params[:biz_location][:name]
    b_level          = params[:biz_location][:location_level]
    b_disbursal_date = params[:biz_location][:center_disbursal_date]
    b_address        = params[:biz_location][:biz_location_address]
    b_originator_by  = params[:biz_location][:originator_by]
    b_managed_by     = params[:managed_by]
    l_product_ids    = params[:lending_product_ids]||[]
    new_product_ids  = params[:new_lending_product_ids]||[]
    b_meeting        = params[:meeting_schedule]
    b_meeting_number = params[:meeting][:meeting_numbers].to_i
    b_frequency      = params[:meeting][:meeting_frequency]
    b_begins_hours   = params[:meeting][:meeting_time_begins_hours].to_i
    b_begins_minutes = params[:meeting][:meeting_time_begins_minutes].to_i
    b_on_date        = Date.parse params[:on_date]
    b_id             = params[:id]
    staff            = StaffMember.get(b_managed_by) unless b_managed_by.blank?
    @biz_location    = BizLocation.get b_id
    recorded_by      = session.user
    performed_by     = recorded_by.staff_member
    b_creation_date  = @biz_location.creation_date
    disbursal_date   = Date.parse(b_disbursal_date) unless b_disbursal_date.blank?

    # VALIDATIONS

    message[:error] << "Name cannot be blank" if b_name.blank?
    message[:error] << "Biz Location cannot be blank" if b_id.blank?
    message[:error] << "Disbursal Date cannot be blank" if b_level == '0' && b_disbursal_date.blank?
    message[:error] << "Meeting Number cannot be blank" if b_level == '0' && !b_meeting.blank? && b_meeting_number.blank?
    message[:error] << "#{staff.to_s} created #{staff.creation_date} has a creation date later than #{b_creation_date}" if !b_managed_by.blank? && staff.creation_date > b_creation_date
    message[:error] << "Please fill right value of time" if b_level == '0' && !b_meeting.blank? && !Constants::Time::MEETING_HOURS_PERMISSIBLE_RANGE.include?(b_begins_hours) &&
      Constants::Time::MEETING_MINUTES_PERMISSIBLE_RANGE.include?(b_begins_minutes)
    message[:error] << "Default Disbursal Date cannot be holiday" if b_level == '0' && !b_meeting.blank? && !configuration_facade.permitted_business_days_in_month(disbursal_date).include?(disbursal_date)
 

    # OPERATIONS PERFORMED
    if message[:error].blank?
      begin
        location_management    = LocationManagement.check_valid_obj(staff, @biz_location, b_on_date, performed_by.id, recorded_by.id) unless b_managed_by.blank?
        values                 = {:name => b_name, :center_disbursal_date => b_disbursal_date, :biz_location_address => b_address}
        values[:originator_by] = b_originator_by unless b_originator_by.blank?
        @biz_location.attributes = values
        if @biz_location.save
          location_management.save unless b_managed_by.blank?
          unless b_meeting.blank?
            msi = MeetingScheduleInfo.new(b_frequency, disbursal_date, b_begins_hours, b_begins_minutes)
            meeting_facade.setup_meeting_schedule(@biz_location, msi, b_meeting_number)
          end
          if b_level == '1'
            @biz_location.lending_product_locations.each do |product|
              product.destroy if l_product_ids.blank? || !l_product_ids.include?(product.lending_product_id)
            end
            new_product_ids.each do |product_id|
              @biz_location.lending_product_locations.first_or_create(:lending_product_id => product_id, :effective_on => b_creation_date, :performed_by => performed_by.id, :recorded_by => recorded_by.id )
            end
          end
          message = {:notice => "#{@biz_location.location_level.name} : '#{@biz_location.name} (Id: #{@biz_location.id})' updated successfully"}
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

    message = {:error => [], :notice => []}

    # GATE-KEEPING
    b_level            = params[:biz_location][:location_level]
    b_creation_date    = Date.parse(params[:biz_location][:creation_date])
    b_name             = params[:biz_location][:name]
    b_address          = params[:biz_location][:biz_location_address]
    b_disbursal_date   = params[:biz_location][:center_disbursal_date].blank? ? '' : Date.parse(params[:biz_location][:center_disbursal_date])
    parent_location_id = params[:parent_location_id]
    loan_product_ids   = params[:lending_product_ids]||[]
    b_originator_by    = params[:biz_location][:originator_by]
    b_managed_by       = params[:managed_by]
    b_meeting          = params[:meeting_schedule]
    b_meeting_number   = params[:meeting][:meeting_numbers].to_i
    b_frequency        = params[:meeting][:meeting_frequency]
    b_begins_hours     = params[:meeting][:meeting_time_begins_hours].to_i
    b_begins_minutes   = params[:meeting][:meeting_time_begins_minutes].to_i
    recorded_by        = session.user
    performed_by       = recorded_by.staff_member
    staff              = StaffMember.get b_managed_by unless b_managed_by.blank?
    parent_location    = BizLocation.get(parent_location_id) unless parent_location_id.blank?


    # VALIDATIONS

    message[:error] << "Name cannot be blank" if b_name.blank?
    message[:error] << "Disbursal Date cannot be blank" if b_level == '0' && b_disbursal_date.blank?
    message[:error] << "Please select Location Level" if b_level.blank?
    message[:error] << "Creation Date cannot blank" if b_creation_date.blank?
    message[:error] << "Meeting Number cannot be blank" if b_level == '0' && !b_meeting.blank? && b_meeting_number.blank?
    message[:error] << "#{staff.to_s} created #{staff.creation_date} has a creation date later than #{b_creation_date}" if !b_managed_by.blank? && staff.creation_date > b_creation_date
    message[:error] << "Please fill right value of time" if b_level == '0' && !b_meeting.blank? && !Constants::Time::MEETING_HOURS_PERMISSIBLE_RANGE.include?(b_begins_hours) &&
      Constants::Time::MEETING_MINUTES_PERMISSIBLE_RANGE.include?(b_begins_minutes)
    message[:error] << "Default Disbursal Date cannot be holiday" if b_level == '0' && !b_meeting.blank? && !configuration_facade.permitted_business_days_in_month(b_disbursal_date).include?(b_disbursal_date)
    message[:error] << "Creation Date cannot be before Parent Location of Creation Date" if !parent_location_id.blank? && parent_location.creation_date > b_creation_date
    # OPERATIONS PERFORMED
    if message[:error].blank?
      begin
        biz_location = location_facade.create_new_location(b_name, b_creation_date, b_level.to_i, b_originator_by, b_address, b_disbursal_date)
        if biz_location.new?
          message = {:error => "Location creation fail"}
        else
          begin
            LocationLink.assign(biz_location, parent_location, b_creation_date) unless parent_location.blank?
            if b_level == "0"
              biz_location.center_cycles.create(:cycle_number => 1, :initiated_by_staff_id => session.user.staff_member.id, :initiated_on => Date.today, :status => Constants::Space::OPEN_CENTER_CYCLE_STATUS, :created_by => session.user.staff_member.id)
              unless b_meeting.blank?
                msi = MeetingScheduleInfo.new(b_frequency, b_disbursal_date, b_begins_hours, b_begins_minutes)
                meeting_facade.setup_meeting_schedule(biz_location, msi, b_meeting_number)
              end
              LocationManagement.assign_manager_to_location(staff, biz_location, b_creation_date, performed_by.id, recorded_by.id) unless b_managed_by.blank?
              msg = "#{biz_location.location_level.name} : '#{biz_location.name} (Id: #{biz_location.id})'successfully created center with center cycle 1"
            else
              if b_level == '1'
                loan_product_ids.each do |product_id|
                  biz_location.lending_product_locations.first_or_create(:lending_product_id => product_id, :effective_on => b_creation_date, :performed_by => performed_by.id, :recorded_by => recorded_by.id )
                end
              end
              msg = "#{biz_location.location_level.name} : '#{biz_location.name} (Id: #{biz_location.id})' successfully created"
            end
            message = {:notice => msg}
          rescue => ex
            message = {:error => "An error has occured: #{ex.message}"}
          end
        end
      rescue => ex
        message = {:error => "An error has occured: #{ex.message}"}
      end
      if message[:error].blank?
        message.delete(:error)
      end
      redirect resource(:biz_locations), :message => message
    else
      valid_params = {}
      params[:biz_location].keys.each do |k, v|
        valid_params[k] = params[:biz_location][k] rescue nil unless params[:biz_location][k].blank?
      end
      message.delete(:notice)
      redirect resource(:biz_locations, valid_params), :message => message
    end

  end

  def show
    @biz_location     = BizLocation.get params[:id]
    location_level    = LocationLevel.first(:level => (@biz_location.location_level.level - 1))
    @parent_locations = BizLocation.all('location_level.level' => @biz_location.location_level.level)
    @child_locations  = location_level.blank? ? [] : location_level.biz_locations
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

    # OPERATIONS PERFORMEDmessage[:error] << "#{staff.to_s} created #{staff.creation_date} has a creation date later than #{b_creation_date}" if !b_managed_by.blank? && staff.creation_date > b_creation_date
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
    @clients      = ClientAdministration.get_clients_administered_by_sql(@biz_location.id, get_effective_date)
    display @clients
  end

  def centers_for_selector
    if params[:id]
      location_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, session.user)
      branch = location_facade.get_location(params[:id])
      effective_date = params[:effective_date]||get_effective_date
      centers = location_facade.get_children_by_sql(branch, effective_date)
      return("<option value=''>Select center</option>"+centers.map{|center| "<option value=#{center.id}>#{center.name}"}.join)
    else
      return("<option value=''>Select center</option>")
    end
  end

  def branches_for_area
    if params[:id]
      location_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, session.user)
      area = location_facade.get_location(params[:id])
      effective_date = params[:effective_date]
      branches = location_facade.get_children_by_sql(area, effective_date)
      return("<option value=''> Select branch </option>"+branches.map{|branch| "<option value=#{branch.id}>#{branch.name}"}.join)
    else
      return("<option value=''> Select branch </option>")
    end
  end

  def staffs_for_selector
    if params[:parent_location_id].blank?
      return("<option value=''>Select Staff Member</option>")
    else
      location_id = params[:child_location_id].blank? ? params[:parent_location_id] : params[:child_location_id]
      staff_members = StaffPosting.get_staff_assigned(location_id.to_i, get_effective_date).map(&:staff_assigned)
      return("<option value=''>Select Staff Member</option>"+staff_members.map{|staff| "<option value=#{staff.id}>#{staff.name}"}.join)
    end
  end

  def clients_for_selector
    if params[:id].blank?
      return("<option value=''>Select Client</option>")
    else
      clients = ClientAdministration.get_clients_administered_by_sql(params[:id].to_i, get_effective_date)
      return("<option value=''>Select Client</option>"+clients.map{|client| "<option value=#{client.id}>#{client.name}"}.join)
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
    @biz_location         = BizLocation.get params[:id]
    level                 = @biz_location.location_level.level
    @child_location_level = LocationLevel.first(:level => level-1)
    @new_biz_location     = @child_location_level.biz_locations.new
    @staff_members        = StaffPosting.get_staff_assigned(@biz_location.id, get_effective_date).map(&:staff_assigned)
    render :biz_location_form, :layout => layout?
  end

  def create_and_assign_location
    # INITIALIZING VARIABLES USED THROUGHTOUT
    message = {:error => [], :notice => []}

    # GATE-KEEPING
    b_level          = params[:biz_location][:location_level]
    b_creation_date  = params[:creation_date].blank? ? '' : Date.parse(params[:creation_date])
    b_name           = params[:biz_location][:name]
    b_id             = params[:id]
    b_disbursal_date = params[:center_disbursal_date].blank? ? '' : Date.parse(params[:center_disbursal_date])
    b_managed_by     = params[:managed_by]
    b_address        = params[:biz_location][:biz_location_address]
    b_originator_by  = params[:biz_location][:originator_by]
    loan_product_ids = params[:lending_product_ids]||[]
    b_meeting        = params[:meeting_schedule]
    b_meeting_number = params[:meeting][:meeting_numbers].to_i
    b_frequency      = params[:meeting][:meeting_frequency]
    b_begins_hours   = params[:meeting][:meeting_time_begins_hours].to_i
    b_begins_minutes = params[:meeting][:meeting_time_begins_minutes].to_i
    recorded_by      = session.user
    performed_by     = recorded_by.staff_member
    @parent_location = BizLocation.get b_id
    staff            = StaffMember.get b_managed_by unless b_managed_by.blank?

    # VALIDATIONS
    message[:error] << "Name cannot be blank" if b_name.blank?
    message[:error] << "Please select Location Level" if b_level.blank?
    message[:error] << "Parent location is invaild" if @parent_location.blank?
    message[:error] << "Meeting Number cannot be blank" if !b_meeting.blank? && b_meeting_number.blank?
    message[:error] << "Please fill right value of time" if !b_meeting.blank? && !Constants::Time::MEETING_HOURS_PERMISSIBLE_RANGE.include?(b_begins_hours) &&
      Constants::Time::MEETING_MINUTES_PERMISSIBLE_RANGE.include?(b_begins_minutes)

    if b_creation_date.blank? || b_disbursal_date.blank?
      message[:error] << "Creation Date cannot be blank" if b_creation_date.blank?
    else
      message[:error] << "#{staff.to_s} created #{staff.creation_date} has a creation date later than #{b_creation_date}" if !b_managed_by.blank? && staff.creation_date > b_creation_date
      message[:error] << "Default Disbursal Date cannot be holiday" if !b_meeting.blank? && !configuration_facade.permitted_business_days_in_month(b_disbursal_date).include?(b_disbursal_date)
      message[:error] << "Creation Date cannot be before Parent Location of Center Creation Date" if !@parent_location.blank? && @parent_location.creation_date > b_creation_date
      message[:error] << "Default Disbursal Date cannot be before Center Creation Date" unless b_disbursal_date.blank? && b_creation_date > b_disbursal_date
    end

    # OPERATIONS PERFORMED
    if message[:error].blank?
      begin
        child_location = location_facade.create_new_location(b_name, b_creation_date, b_level.to_i, b_originator_by, b_address, b_disbursal_date)
        if child_location.new?
          message = {:notice => "Location creation fail"}
        else
          location_facade.assign(child_location, @parent_location, b_creation_date)
          unless b_meeting.blank?
            msi = MeetingScheduleInfo.new(b_frequency, b_disbursal_date, b_begins_hours, b_begins_minutes)
            meeting_facade.setup_meeting_schedule(child_location, msi, b_meeting_number)
          end
          LocationManagement.assign_manager_to_location(staff, child_location, b_creation_date, performed_by.id, recorded_by.id) unless b_managed_by.blank?
          if b_level == "0"
            child_location.center_cycles.create(:cycle_number => 1, :initiated_by_staff_id => session.user.staff_member.id, :initiated_on => Date.today, :status => Constants::Space::OPEN_CENTER_CYCLE_STATUS, :created_by => session.user.staff_member.id)
            msg = "#{child_location.location_level.name} : '#{child_location.name} (Id: #{child_location.id})' successfully created with center cycle 1"
          else
            if b_level == '1'
              loan_product_ids.each do |product_id|
                child_location.lending_product_locations.first_or_create(:lending_product_id => product_id, :effective_on => b_creation_date, :performed_by => performed_by.id, :recorded_by => recorded_by.id )
              end
            end
            msg = "#{child_location.location_level.name} : '#{child_location.name} (Id: #{child_location.id})' successfully created"
          end
          message = {:notice => msg}
        end
      rescue => ex
        message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    #REDIRECT/RENDER
    if message[:error].blank?
      message.delete(:error)
      msg_str = message[:notice].to_s
      redirect url("user_locations/show/#{@parent_location.id}?success_message=#{msg_str}#location")
    else
      message.delete(:notice)
      msg_str = message[:error].flatten.join(', ')
      redirect url("user_locations/show/#{@parent_location.id}?error_message=#{msg_str}#location")
    end
  end

  def loan_products
    @location = BizLocation.get(params[:id])
    @parent_location = LocationLink.get_parent(@location, get_effective_date)
    @client = Client.get(params[:client_id]) unless params[:client_id].blank?
    @lending_products = @parent_location.lending_products
    display @lending_products
  end

  def fetch_child_locations
    @colName = ["id" , "name", 'biz_location_address', 'creation_date']
    @colCount = params[:iColumns]
    order = @colName[params[:iSortCol_0].to_i].blank? ? @colName.first : [@colName[params[:iSortCol_0].to_i]]
    limit = params[:iDisplayLength].to_i <= 0 ? 10 : params[:iDisplayLength].to_i
    @parent_location = BizLocation.get(params[:id])
    @child_locations = LocationLink.get_children_by_sql(@parent_location, get_effective_date)
    @locations = BizLocation.all(:order => order, :id => @child_locations.map(&:id), :limit => limit, :offset => params[:iDisplayStart].to_i, :conditions => [ ' id LIKE ? OR name LIKE ? OR biz_location_address LIKE ? OR creation_date LIKE ?', '%'+params[:sSearch]+'%', '%'+params[:sSearch]+'%','%'+params[:sSearch]+'%','%'+params[:sSearch]+'%'])
    @iTotalRecords = @child_locations.count
    @iTotalDisplayRecords = params[:sSearch].blank? ? @iTotalRecords : @locations.size
    @sEcho = params[:sEcho].to_i
    render :template => 'location_levels/fetch_locations', :layout => layout?
  end

  def location_checklists
    @parent_location = params[:parent_location_id].blank? ? '' : BizLocation.get(params[:parent_location_id])
    @child_location  = params[:child_location_id].blank? ? '' : BizLocation.get(params[:child_location_id])
    @clients         = @child_location.blank? ? [] : ClientAdministration.get_clients_administered(@child_location.id, get_effective_date)
    display @clients
  end

end
