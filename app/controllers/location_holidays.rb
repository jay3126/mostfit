class LocationHolidays < Application

  def index
    if params[:biz_location_id].blank?
      @holidays = LocationHoliday.all
    else
      @biz_location = BizLocation.get params[:biz_location_id]
      @holidays     = @biz_location.location_holidays
    end
    if request.xhr?
      render :template => 'location_holidays/index', :layout => layout?
    else
      display @holidays
    end
  end

  def new
    @holiday  = LocationHoliday.new
    @biz_location = BizLocation.get(params[:biz_location_id]) unless params[:biz_location_id].blank?
    if request.xhr?
      render :template => 'location_holidays/new', :layout => layout?
    else
      display @holiday
    end
  end

  def edit
    @holiday = LocationHoliday.get params[:id]
    if request.xhr?
      render :template => 'location_holidays/edit', :layout => layout?
    else
      display @holidays
    end
  end

  def create
    # INITIALIZING VARIABLES USED THROUGHTOUT

    @message = {}

    # GATE-KEEPING

    name         = params[:location_holiday][:name]
    on_date      = params[:location_holiday][:on_date]
    move_date    = params[:location_holiday][:move_work_to_date]
    by_staff     = params[:location_holiday][:performed_by]
    by_user      = session.user.id
    location_ids = params[:biz_location]

    # VALIDATIONS

    @message[:error] = "Name cannot be blank" if name.blank?
    @message[:error] = "On Date cannot be blank" if on_date.blank?
    @message[:error] = "Move Date cannot be blank" if move_date.blank?
    @message[:error] = "Staff Member cannot be blank" if by_staff.blank?

    # OPERATIONS PERFORMED
    if @message[:error].blank?
      begin
        at_locations = location_ids.blank? ? [] : BizLocation.all(:id=> location_ids)
        holiday = LocationHoliday.setup_holiday(at_locations, name, on_date, move_date, by_staff, by_user)
        if holiday.new?
          @message = {:notice => "Holiday creation fail"}
        else
          @message = {:notice => " Holiday successfully created"}
        end
      rescue => ex
        @message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    #REDIRECT/RENDER
    redirect request.referer, :message => @message
  end

  def show
    @holiday = LocationHoliday.get params[:id]
    display @holiday
  end

  def update
    # INITIALIZING VARIABLES USED THROUGHTOUT

    @message = {}

    # GATE-KEEPING

    id           = params[:id]
    name         = params[:location_holiday][:name]
    on_date      = params[:location_holiday][:on_date]
    move_date    = params[:location_holiday][:move_work_to_date]
    location_ids = params[:biz_location]

    # VALIDATIONS

    @message[:error] = "Name cannot be blank" if name.blank?
    @message[:error] = "On Date cannot be blank" if on_date.blank?
    @message[:error] = "Move Date cannot be blank" if move_date.blank?
    @holiday         = LocationHoliday.get id
    # OPERATIONS PERFORMED
    if @message[:error].blank?
      begin
        at_locations = location_ids.blank? ? [] : BizLocation.all(:id=> location_ids)
        holiday = @holiday.update_holiday(at_locations, name, on_date, move_date)
        if holiday.new?
          @message = {:notice => "Holiday Updation fail"}
        else
          @message = {:notice => " Holiday successfully Updated"}
        end
      rescue => ex
        @message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    #REDIRECT/RENDER
    redirect request.referer, :message => @message
  end

  def holiday_for_location
    @biz_location = BizLocation.get params[:biz_location_id]
    @parent_location = LocationLink.get_parent(@biz_location)
    location_id = @biz_location.location_level.level == 0 ? @parent_location.id : @biz_location.id
    @staff_members = StaffPosting.get_staff_assigned(location_id, get_effective_date).map(&:staff_assigned)
    if request.xhr?
      render :template => 'location_holidays/holiday_for_location', :layout => layout?
    else
      display @biz_location
    end
  end

  def create_holiday_for_location
    # INITIALIZING VARIABLES USED THROUGHTOUT

    @message = {}

    # GATE-KEEPING

    holiday_ids  = params[:location_holiday]
    location_id  = params[:biz_location_id]
    performed_by = params[:staff_member_id]
    recorded_by  = session.user.id

    # VALIDATIONS

    @message[:error] = "Staff Member cannot be blank" if performed_by.blank?
    @message[:error] = "Holiday cannot be blank" if holiday_ids.blank?
    @biz_location    = BizLocation.get location_id

    # OPERATIONS PERFORMED
    if @message[:error].blank?
      begin
        @holidays = holiday_ids.blank? ? [] : LocationHoliday.all(:id => holiday_ids)
        holiday_count = @biz_location.location_holidays.count
        LocationHoliday.save_holiday_for_location(@biz_location, @holidays, performed_by, recorded_by)
        if holiday_count+@holidays.count == @biz_location.reload.location_holidays.count
          @message = {:notice => " Holiday successfully Assigned"}
        else
          @message = {:error => "Holiday cannot assign to location"}
        end
      rescue => ex
        @message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    #REDIRECT/RENDER
    redirect request.referer, :message => @message
  end

  def destroy
    @holiday = LocationHoliday.get params[:id]
    @holiday_admins = @holiday.holiday_administrations
    location_ids = params[:location_holiday]
    child_locations = []
    message = {}
    message[:error] = "Please Select Location" if params[:location_holiday].blank?
    if message[:error].blank?
      at_locations = BizLocation.all(:id => location_ids)
      @holiday_admins.each do |holiday|
        holiday.destroy if location_ids.include?(holiday.biz_location_id.to_s)
      end
      at_locations.each{|location| child_locations << LocationLink.all_children(location)}
      BaseScheduleLineItem.all('loan_base_schedule.lending.administered_at_origin' => child_locations.flatten.uniq.map(&:id), :on_date => @holiday.move_work_to_date, :actual_date.not => @holiday.move_work_to_date).update(:on_date => @holiday.on_date)
      MeetingCalendar.all(:location_id => child_locations.flatten.uniq.map(&:id), :on_date => @holiday.move_work_to_date, :actual_date.not => @holiday.move_work_to_date).update(:on_date => @holiday.on_date)
      message[:notice] = "Holiday Successfully Deleted from Locations"
    end
    redirect request.referer, :message => message
  end
end