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
      at_locations.each{|location| child_locations << LocationLink.all_children(location) << location}
      BaseScheduleLineItem.all('loan_base_schedule.lending.administered_at_origin' => child_locations.flatten.uniq.map(&:id), :on_date => @holiday.move_work_to_date, :actual_date.not => @holiday.move_work_to_date).update(:on_date => @holiday.on_date)
      MeetingCalendar.all(:location_id => child_locations.flatten.uniq.map(&:id), :on_date => @holiday.move_work_to_date, :actual_date.not => @holiday.move_work_to_date).update(:on_date => @holiday.on_date)
      message[:notice] = "Holiday Successfully Deleted from Locations"
    end
    redirect request.referer, :message => message
  end

  def download_custom_calendar_format
    send_file(File.join(Merb.root,'doc','custom_calendar','default_custom_calendar.xls'))
  end

  def custom_calendar
    @data = {}
    if params[:custom_calender_file].blank?
      year = params[:custom_calendar_year]||get_effective_date.year
      first_date = Date.parse("01-01-#{year}")
      last_date = Date.parse("31-12-#{year}")
      @custom_calendar_dates = CustomCalendar.all(:on_date => (first_date..last_date))
    else
      file_name = 'custome_calendar'
      folder = File.join(Merb.root, "doc","custom_calendar","#{Date.today}")
      filename = params[:custom_calender_file][:filename]
      FileUtils.mkdir_p(folder)
      filepath = File.join(folder, filename)
      FileUtils.mv(params[:custom_calender_file][:tempfile].path, filepath)
      User.convert_xls_to_csv(filepath, folder+"/#{file_name}")
      @data = LocationHoliday.new.csv_file_read(folder, file_name)
    end
    display @data
  end

  def edit_custom_calendar
    @custom_year = params[:custom_calendar_year]||get_effective_date.year
    first_date = Date.parse("01-01-#{@custom_year}")
    last_date = Date.parse("31-12-#{@custom_year}")
    @custom_calendar_dates = CustomCalendar.all(:on_date => (first_date..last_date))
    display @custom_calendar_dates
  end

  def update_custom_calendar
    @message = {:error => [], :notice => []}
    cc_params = params[:custom_calendar]
    valid_params = cc_params.select{|key, value| value[:update_calendar]==key}.map(&:last)
    @message[:error] << 'Please Select Custom Calendar Date For Updated' if valid_params.blank?

    if @message[:error].blank?
      begin
        valid_params.each do |values|
          obj = CustomCalendar.get(values[:update_calendar])
          unless obj.blank?
            obj.collection_date = values[:collection_date].blank? ? nil : Date.parse(values[:collection_date])
            obj.holiday_name = values[:holiday_name]
            obj.save
          end
        end
      rescue => ex
        @message = {:error => "An error has occured: #{ex.message}"}
      end
      @message[:notice] = "Custom Calendar updated successfully"
    end

    @message[:error].blank? ? @message.delete(:error) : @message.delete(:notice)
    redirect resource(:location_holidays, :edit_custom_calendar, :custom_calendar_year => params[:custom_calendar_year].to_s), :message => @message
  end

  def record_custom_calendar
    @message = {:error => [], :notice => []}
    recorded_by = session.user
    performed_by = recorded_by.staff_member
    begin
      CustomCalendar.save_custom_calendar(performed_by.id, recorded_by.id, params[:custom_calendar_year], params[:custom_calendar])
      @message[:notice] = "Custom Calendar saved successfully"
    rescue => ex
      @message = {:error => "An error has occured: #{ex.message}"}
    end

    @message[:error].blank? ? @message.delete(:error) : @message.delete(:notice)
    redirect resource(:location_holidays, :custom_calendar, :custom_calendar_year => params[:custom_calendar_year].to_s, :submit => 'Go'), :message => @message
  end
end