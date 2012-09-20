class BizLocations < Application

  def index
    @location_levels = LocationLevel.all
    @biz_locations   = BizLocation.all.group_by{|c| c.location_level.level}
    @biz_location    = BizLocation.new()
    display @location_levels
  end

  def edit
    @biz_location     = BizLocation.get params[:id]
    @staff_members    = StaffPosting.get_staff_assigned(@biz_location.id, get_effective_date).map(&:staff_assigned) rescue []
    @managed_by_staff = location_facade.location_managed_by_staff(@biz_location.id, get_effective_date).manager_staff_member rescue ''
    display @biz_location
  end

  def update_biz_location
    # INITIALIZING VARIABLES USED THROUGHTOUT

    message = {}
    # GATE-KEEPING

    b_name           = params[:biz_location][:name]
    b_disbursal_date = params[:biz_location][:center_disbursal_date]
    b_address        = params[:biz_location][:biz_location_address]
    b_originator_by  = params[:biz_location][:originator_by]
    b_managed_by     = params[:managed_by]
    b_on_date        = Date.parse params[:on_date]
    b_id             = params[:id]
    staff            = StaffMember.get(b_managed_by) unless b_managed_by.blank?

    # VALIDATIONS

    message[:error] = "Name cannot be blank" if b_name.blank?
    message[:error] = "Biz Location cannot be blank" if b_id.blank?
    @biz_location   = BizLocation.get b_id
    recorded_by     = session.user
    performed_by    = recorded_by.staff_member

    # OPERATIONS PERFORMED
    if message[:error].blank?
      begin
        location_management      = LocationManagement.check_valid_obj(staff, @biz_location, b_on_date, performed_by.id, recorded_by.id) unless b_managed_by.blank?
        @biz_location.attributes = {:name => b_name, :center_disbursal_date => b_disbursal_date, :biz_location_address => b_address, :originator_by => b_originator_by}
        if @biz_location.save
          location_management.save unless b_managed_by.blank?
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
    parent_location = BizLocation.get(parent_location_id) unless parent_location_id.blank?
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
              location_facade.create_center_cycle(b_creation_date, biz_location.id)
              unless b_meeting.blank?
                msi = MeetingScheduleInfo.new(b_frequency, b_disbursal_date, b_begins_hours, b_begins_minutes)
                meeting_facade.setup_meeting_schedule(biz_location, msi)
                meeting_facade.setup_meeting_calendar_for_location(biz_location, b_disbursal_date, b_meeting_number)
              end
              LocationManagement.assign_manager_to_location(staff, biz_location, b_creation_date, performed_by.id, recorded_by.id) unless b_managed_by.blank?
              msg = "#{biz_location.location_level.name} : '#{biz_location.name} (Id: #{biz_location.id})'successfully created center with center cycle 1"
            else
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
    end

    #REDIRECT/RENDER
    message[:error].blank? ? message.delete(:error) : message.delete(:notice)
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

  def staffs_for_selector
    if params[:parent_location_id].blank?
      return("<option value=''>Select Staff Member</option>")
    else
      location_id = params[:child_location_id].blank? ? params[:parent_location_id] : params[:child_location_id]
      staff_members = StaffPosting.get_staff_assigned(location_id.to_i, get_effective_date).map(&:staff_assigned)
      return("<option value=''>Select Staff Member</option>"+staff_members.map{|staff| "<option value=#{staff.id}>#{staff.name}"}.join)
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
    render :partial => 'biz_locations/location_fields', :layout => layout?
  end

  def create_and_assign_location
    # INITIALIZING VARIABLES USED THROUGHTOUT
    message = {:error => [], :notice => []}

    # GATE-KEEPING

    b_level          = params[:biz_location][:location_level]
    b_creation_date  = Date.parse(params[:creation_date])
    b_name           = params[:biz_location][:name]
    b_id             = params[:id]
    b_disbursal_date = params[:biz_location][:center_disbursal_date].blank? ? '' : Date.parse(params[:biz_location][:center_disbursal_date])
    b_managed_by     = params[:managed_by]
    b_address        = params[:biz_location][:biz_location_address]
    b_originator_by  = params[:biz_location][:originator_by]
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
    message[:error] << "Creation Date cannot blank" if b_creation_date.blank?
    message[:error] << "Parent location is invaild" if @parent_location.blank?
    message[:error] << "Please select Driginator By" if b_originator_by.blank?
    message[:error] << "Meeting Number cannot be blank" if !b_meeting.blank? && b_meeting_number.blank?
    message[:error] << "#{staff.to_s} created #{staff.creation_date} has a creation date later than #{b_creation_date}" if !b_managed_by.blank? && staff.creation_date > b_creation_date
    message[:error] << "Please fill right value of time" if !b_meeting.blank? && !Constants::Time::MEETING_HOURS_PERMISSIBLE_RANGE.include?(b_begins_hours) &&
      Constants::Time::MEETING_MINUTES_PERMISSIBLE_RANGE.include?(b_begins_minutes)
    message[:error] << "Default Disbursal Date cannot be holiday" if !b_meeting.blank? && !configuration_facade.permitted_business_days_in_month(b_disbursal_date).include?(b_disbursal_date)
    
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
            meeting_facade.setup_meeting_schedule(child_location, msi)
            meeting_facade.setup_meeting_calendar_for_location(child_location, b_disbursal_date, b_meeting_number)
          end
          LocationManagement.assign_manager_to_location(staff, child_location, b_creation_date, performed_by.id, recorded_by.id) unless b_managed_by.blank?
          if b_level == "0"
            location_facade.create_center_cycle(b_creation_date, child_location.id)
            msg = "#{child_location.location_level.name} : '#{child_location.name} (Id: #{child_location.id})' successfully created with center cycle 1"
          else
            msg = "#{child_location.location_level.name} : '#{child_location.name} (Id: #{child_location.id})' successfully created"
          end
          message = {:notice => msg}
        end
      rescue => ex
        message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    #REDIRECT/RENDER
    message[:error].blank? ? message.delete(:error) : message.delete(:notice)
    redirect url(:controller => :user_locations, :action => :show, :id => @parent_location.id), :message => message

  end

end
