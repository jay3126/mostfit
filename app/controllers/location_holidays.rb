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
    if request.xhr?
      render :template => 'location_holidays/new', :layout => layout?
    else
      display @holiday
    end
  end

  def create
    # INITIALIZING VARIABLES USED THROUGHTOUT

    @message = {}

    # GATE-KEEPING

    name        = params[:location_holiday][:name]
    on_date     = params[:location_holiday][:on_date]
    move_date   = params[:location_holiday][:move_work_to_date]
    by_staff    = params[:location_holiday][:performed_by]
    by_user     = session.user.id
    location_id = params[:location_holiday][:biz_location]

    # VALIDATIONS

    @message[:error] = "Name cannot be blank" if name.blank?
    @message[:error] = "On Date cannot be blank" if on_date.blank?
    @message[:error] = "Move Date cannot be blank" if move_date.blank?
    @message[:error] = "Staff Member cannot be blank" if by_staff.blank?
    @message[:error] = "Location cannot be blank" if location_id.blank?

    # OPERATIONS PERFORMED
    if @message[:error].blank?
      begin
        at_location = BizLocation.get location_id
        holiday = LocationHoliday.setup_holiday(at_location, name, on_date, move_date, by_staff, by_user)
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
end